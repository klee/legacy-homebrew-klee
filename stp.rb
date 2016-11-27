class Stp < Formula
  desc "Simple Theorem Prover"
  homepage "https://stp.github.io"

  stable do
      url "https://github.com/stp/stp/archive/stp-2.2.0.tar.gz"
      sha256 "f0e3d25a0655d28ccddc0705e1330e0523dd8e93b8717b654e0de6181ad85a97"
  end

  head do
    url "https://github.com/stp/stp.git", :branch => "stp-220"
  end

  bottle do
    rebuild 1
    root_url "https://www.doc.ic.ac.uk/~amattave/brew"
    sha256 "228a11559970fad33126f56a005b733f645ec00c9c6f10f23c7977fe292ec5c0" => :sierra
  end
  
  depends_on "cmake" => :build
  depends_on "minisat"
  
  def install
    system "cmake" , "-DCMAKE_INSTALL_PREFIX=#{prefix}",
                     "-DENABLE_PYTHON_INTERFACE:BOOL=OFF",
                     "."
    system "make"
    system "make", "install"
  end

  test do
    system "true"
  end
end
