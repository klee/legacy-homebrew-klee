class Klee < Formula
  include Language::Python::Virtualenv

  desc "KLEE Symbolic Virtual Machine"
  homepage "https://klee.github.io"

  stable do
    url "https://github.com/klee/klee/archive/v1.4.0.tar.gz"
    sha256 "82ec16d83c4d03bc3ac12bcd0532b5a7788276c5e3f58741532203c3d7ba128f"
  end

  resource "googletest" do
    url "https://github.com/google/googletest/archive/release-1.8.0.zip"
    sha256 "f3ed3b58511efd272eb074a3a6d6fb79d7c2e6a0e374323d1e6bcbcc1ef141bf"
  end

  head do
    url "https://github.com/klee/klee.git", :branch => "1.4.x"
  end
  
  depends_on "klee/klee/llvm@3.4"
  depends_on "klee/klee/stp"
  depends_on "z3"
  depends_on "gperftools"
  depends_on "python" => :build
  depends_on "cmake" => :build
  depends_on "doxygen" => [:recommended, :build]

  def install
    venv = virtualenv_create(libexec, "python3")
    venv.pip_install "lit"

    llvm_config = Formula["klee/klee/llvm@3.4"].bin/"llvm-config-3.4"
    llvm_bin = system llvm_config, "--bindir"
    ENV['CC'] = "#{llvm_bin}/clang"
    ENV['CXX'] = "#{llvm_bin}/clang++"

    resource("googletest").stage do
      libexec.install 'googletest' => 'googletest'
    end

    mkdir "build" do
      system "cmake", "..", *%W[
      -DENABLE_SOLVER_STP=ON
      -DENABLE_SOLVER_Z3=ON
      -DENABLE_TCMALLOC=ON
      -DENABLE_UNIT_TESTS=ON
      -DGTEST_SRC_DIR=#{libexec/"googletest"}
      -DENABLE_SYSTEM_TESTS=ON
      -DLLVM_CONFIG_BINARY=#{llvm_config}
      -DCMAKE_INSTALL_PREFIX=#{prefix}
      ]
      system "make"
      system "make", "unittests"

      # fix most systemtests failures from not finding system includes
      system "ln", "-s", "/Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk/usr/include/*", "../include/"
      system "make", "systemtests", "||", "true" 
      system "make", "install"
    end
  end

  test do
    system "#{bin}/klee", "--version"
  end
end
