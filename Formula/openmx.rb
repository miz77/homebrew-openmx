class Openmx < Formula
  desc "DFT package for large-scale material simulations"
  homepage "https://www.openmx-square.org/"
  url "https://www.openmx-square.org/openmx4.0.tar.gz"
  version "4.0.1"
  sha256 "8d5338faf70885f276352bbd2826cdfed2ffd08f33eca58752666d79a7d0c3bf"
  license "GPL-3.0-only"

  depends_on "fftw"
  depends_on "gcc"
  depends_on "open-mpi"
  depends_on "openblas"
  depends_on "scalapack"

  resource "patch4.0.1" do
    url "https://www.openmx-square.org/bugfixed/26May08/patch4.0.1.tar.gz"
    sha256 "c5312eeee13e17e0123beeb4eb2379bcf7c7cafa1815b1dcf6846452f9620bef"
  end

  def install
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

    ENV["OMPI_CC"] = (gcc.opt_bin/"gcc-#{gcc_major}").to_s
    ENV["OMPI_FC"] = (gcc.opt_bin/"gfortran-#{gcc_major}").to_s

    mpicc = openmpi.opt_bin/"mpicc"
    mpif90 = openmpi.opt_bin/"mpif90"
    stagebin = buildpath/"stage/bin"
    mkdir_p stagebin

    ccflags = %W[
      #{mpicc}
      -Dnosse
      -fcommon
      -O2
      -fopenmp
      -Wno-implicit-function-declaration
      -I#{fftw.opt_include}
    ]

    fcflags = %W[
      #{mpif90}
      -O2
      -fopenmp
      -fallow-argument-mismatch
    ]

    libs = %W[
      -L#{scalapack.opt_lib}
      -L#{openblas.opt_lib}
      -L#{fftw.opt_lib}
      -lscalapack
      -lopenblas
      -lfftw3
    ] + shell_output("#{mpif90} --showme:link").split

    cd "source" do
      inreplace "Input_std.c", "../DFT_DATA19", "#{opt_pkgshare}/DFT_DATA19"

      inreplace "makefile" do |s|
        {
          "CC"      => ccflags.join(" "),
          "FC"      => fcflags.join(" "),
          "LIB"     => libs.join(" "),
          "DESTDIR" => stagebin,
        }.each do |key, value|
          pattern = /^#{Regexp.escape(key)}\s*=.*$/
          raise "failed to replace #{key} in makefile" unless s.sub!(pattern, "#{key} = #{value}")
        end

        s.gsub!(/^\tgcc\b/, "\t$(CC)")
        unless s.sub!(
          /^\t\$\(CC\) \$\(OBJS\) \$\(LIB\) -lm -o openmx$/,
          "\t$(FC) $(OBJS) $(LIB) -lm -o openmx",
        )
          raise "failed to switch openmx linker to FC"
        end
      end

      system "make", "all"
    end

    bin.install Dir["#{stagebin}/*"]
    pkgshare.install "DFT_DATA19"
    (pkgshare/"examples").install "work"
  end

  test do
    (testpath/"methane.dat").write <<~EOS
      System.CurrrentDirectory         ./
      System.Name                      met
      level.of.stdout                  1
      level.of.fileout                 1

      Species.Number                   2
      <Definition.of.Atomic.Species
       H   H5.0-s1          H_PBE19
       C   C5.0-s1p1        C_PBE19
      Definition.of.Atomic.Species>

      Atoms.Number                     5
      Atoms.SpeciesAndCoordinates.Unit Ang
      <Atoms.SpeciesAndCoordinates
       1  C      0.000000    0.000000    0.000000     2.0  2.0
       2  H     -0.889981   -0.629312    0.000000     0.5  0.5
       3  H      0.000000    0.629312   -0.889981     0.5  0.5
       4  H      0.000000    0.629312    0.889981     0.5  0.5
       5  H      0.889981   -0.629312    0.000000     0.5  0.5
      Atoms.SpeciesAndCoordinates>
      Atoms.UnitVectors.Unit           Ang
      <Atoms.UnitVectors
        10.0   0.0   0.0
         0.0  10.0   0.0
         0.0   0.0  10.0
      Atoms.UnitVectors>

      scf.XcType                       GGA-PBE
      scf.SpinPolarization             off
      scf.ElectronicTemperature        300.0
      scf.energycutoff                 120.0
      scf.maxIter                      100
      scf.EigenvalueSolver             cluster
      scf.Kgrid                        1 1 1
      scf.Mixing.Type                  rmm-diis
      scf.Init.Mixing.Weight           0.200
      scf.Min.Mixing.Weight            0.001
      scf.Max.Mixing.Weight            0.200
      scf.Mixing.History               7
      scf.Mixing.StartPulay            4
      scf.criterion                    1.0e-10
      scf.lapack.dste                  dstevx

      MD.Type                          nomd
      MD.maxIter                       1
      MD.TimeStep                      1.0
      MD.Opt.criterion                 1.0e-4
    EOS

    mpirun = Formula["open-mpi"].opt_bin/"mpirun"
    output = shell_output("#{mpirun} -np 1 #{bin}/openmx methane.dat -nt 1")
    assert_match "The calculation was normally finished", output
    assert_path_exists testpath/"met.out"
    assert_match "Total Computational Time", (testpath/"met.out").read
  end
end
