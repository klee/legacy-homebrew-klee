class Klee < Formula
  desc "KLEE Symbolic Virtual Machine"
  homepage "https://klee.github.io"

  stable do
      url "https://github.com/klee/klee/archive/v1.2.0.tar.gz"
      sha256 "197c81434bcdd3c57c1549896b78b0397bd1aca6a3038ca80f6f7e0c997fc5f7"
  end

  head do
    url "https://github.com/klee/klee.git", :branch => "1.2.x"
  end
  
  depends_on "andreamattavelli/klee/llvm34"
  depends_on "andreamattavelli/klee/stp"

  def install
    system "./configure", "--with-stp=#{Formula["andreamattavelli/klee/stp"].opt_prefix}",
                          "--prefix=#{prefix}"
    system "make"
    system "make", "install"
  end

  test do
    system "#{bin}/klee", "--version"
  end
end
