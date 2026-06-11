class Openmx < Formula
  desc "DFT package for large-scale material simulations"
  homepage "https://www.openmx-square.org/"
  url "https://www.openmx-square.org/openmx4.0.tar.gz"
  # Upstream ships 4.0.1 as the 4.0 tarball plus the official 4.0.1 bugfix.
  version "4.0.1"
  sha256 "8d5338faf70885f276352bbd2826cdfed2ffd08f33eca58752666d79a7d0c3bf"
  license "GPL-3.0-only"

  depends_on "fftw"
  depends_on "gcc" # for gfortran
  depends_on "open-mpi"
  depends_on "openblas"
  depends_on "scalapack"

  on_macos do
    depends_on "libomp"
  end

  resource "patch4.0.1" do
    url "https://www.openmx-square.org/bugfixed/26May08/patch4.0.1.tar.gz"
    sha256 "c5312eeee13e17e0123beeb4eb2379bcf7c7cafa1815b1dcf6846452f9620bef"
  end

  def install
    # The official 4.0.1 patch is distributed as replacement files.
    resource("patch4.0.1").stage do
      cp "Band_DFT_Dosout.c", buildpath/"source/Band_DFT_Dosout.c"
      cp "Mulliken_Charge.c", buildpath/"source/Mulliken_Charge.c"
      cp "GaAs.dat", buildpath/"work/GaAs.dat"
    end

    gcc = Formula["gcc"]
    gcc_major = gcc.version.major
    openmpi = Formula["open-mpi"]
    openblas = Formula["openblas"]
    scalapack = Formula["scalapack"]
    fftw = Formula["fftw"]
    libomp = Formula["libomp"] if OS.mac?

    ENV["OMPI_FC"] = (gcc.opt_bin/"gfortran-#{gcc_major}").to_s

    mpicc = openmpi.opt_bin/"mpicc"
    mpif90 = openmpi.opt_bin/"mpif90"
    elpa = buildpath/"source/elpa-2018.05.001"
    stagebin = buildpath/"stage/bin"
    mkdir_p stagebin

    # Use upstream's portable C paths for SSE intrinsics and compiler-specific
    # inline/alignment handling.
    ccflags = %W[
      #{mpicc}
      -Dnosse
      -Dkcomp
      -fcommon
      -O2
      -Wno-implicit-function-declaration
      -Wno-incompatible-pointer-types
      -Wno-incompatible-function-pointer-types
      -I#{fftw.opt_include}
      -I#{elpa}
    ]

    fcflags = %W[
      #{mpif90}
      -O2
      -fallow-argument-mismatch
      -I#{elpa}
    ]

    libs = %W[
      -L#{scalapack.opt_lib}
      -L#{openblas.opt_lib}
      -L#{fftw.opt_lib}
      -lscalapack
      -lopenblas
      -lfftw3
    ] + Utils.safe_popen_read(mpif90, "--showme:link").split

    if OS.mac?
      # Avoid gfortran's libgomp on macOS and link OpenMP through libomp.
      ccflags.push "-Xpreprocessor", "-fopenmp", "-I#{libomp.opt_include}"
      libs.push "-L#{libomp.opt_lib}", "-lomp"
    else
      ccflags << "-fopenmp"
      fcflags << "-fopenmp"
    end

    ENV.deparallelize

    cd "source" do
      inreplace "Input_std.c", "../DFT_DATA19", "#{opt_pkgshare}/DFT_DATA19"

      inreplace "makefile" do |s|
        unless s.sub!(
          /^\t\$\(CC\) \$\(OBJS\) \$\(LIB\) -lm -o openmx$/,
          "\t$(FC) $(OBJS) $(LIB) -lm -o openmx",
        )
          raise "failed to switch openmx linker to FC"
        end
      end

      system "make", "all",
             "CC=#{ccflags.join(" ")}",
             "FC=#{fcflags.join(" ")}",
             "LIB=#{libs.join(" ")}",
             "DESTDIR=#{stagebin}"
    end

    staged_bins = stagebin.children.sort_by(&:to_s)
    bin.install staged_bins

    pkgshare.install "DFT_DATA19"
    (pkgshare/"examples").install "work"
  end

  test do
    ENV["OMP_NUM_THREADS"] = "1"

    assert_path_exists bin/"openmx"
    cp pkgshare/"examples/work/Methane.dat", testpath/"Methane.dat"

    mpirun = Formula["open-mpi"].opt_bin/"mpirun"
    output = shell_output("#{mpirun} -np 1 #{bin}/openmx Methane.dat -nt 1")
    assert_match "The calculation was normally finished", output
    assert_path_exists testpath/"met.out"
    assert_match "Total Computational Time", (testpath/"met.out").read
  end
end
