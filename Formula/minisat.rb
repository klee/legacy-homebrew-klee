class Minisat < Formula
  desc "Boolean satisfiability (SAT) problem solver"
  homepage "http://minisat.se"
  head "https://github.com/stp/minisat.git", :branch => "master"

  depends_on "cmake" => :build

  def install
    mkdir "build" do
      system "cmake" , "-DSTATIC_BINARIES=ON",
                       "-DCMAKE_INSTALL_PREFIX=#{prefix}",
                       ".."
      system "make"
      system "make", "install"
    end
  end

  test do
    dimacs = <<-EOS.undent
      p cnf 3 2
      1 -3 0
      2 3 -1 0
    EOS

    assert_match(/^SATISFIABLE$/, pipe_output("#{bin}/minisat", dimacs, 10))
  end
end
