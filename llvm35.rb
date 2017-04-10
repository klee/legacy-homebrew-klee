class Llvm35 < Formula
  desc "Next-gen compiler infrastructure"
  homepage "http://llvm.org/"

  stable do
    url "http://llvm.org/releases/3.5.1/llvm-3.5.1.src.tar.xz"
    sha256 "bf3275d2d7890015c8d8f5e6f4f882f8cf3bf51967297ebe74111d6d8b53be15"

    resource "clang" do
      url "http://llvm.org/releases/3.5.1/cfe-3.5.1.src.tar.xz"
      sha256 "6773f3f9cf815631cc7e779ec134ddd228dc8e9a250e1ea3a910610c59eb8f5c"
    end

    resource "libcxx" do
      url "http://llvm.org/releases/3.5.1/libcxx-3.5.1.src.tar.xz"
      sha256 "a16d0ae0c0cf2c8cebb94fafcb907022cd4f8579ebac99a4c9919990a37ad475"
    end

    resource "lld" do
      url "http://llvm.org/releases/3.5.1/lld-3.5.1.src.tar.xz"
      sha256 "f29f684723effd204b6fe96edb1bf2f66f0f81297230bc92b8cc514f7a24236f"
    end

    resource "lldb" do
      url "http://llvm.org/releases/3.5.1/lldb-3.5.1.src.tar.xz"
      sha256 "e8b948c6c85cd61bd9a48361959401b9c631fa257c0118db26697c5d57460e13"
    end

    resource "clang-tools-extra" do
      url "http://llvm.org/releases/3.5.1/clang-tools-extra-3.5.1.src.tar.xz"
      sha256 "e8d011250389cfc36eb51557ca25ae66ab08173e8d53536a0747356105d72906"
    end
  end

  bottle do
    rebuild 1
    root_url "https://www.doc.ic.ac.uk/~amattave/brew"
    sha256 "5cc02999c31a3a48357c56782adc62db31bed17410ee83d490bf4a58438c05fa" => :sierra
  end

  head do
    url "http://llvm.org/git/llvm.git", :branch => "release_35"

    resource "clang" do
      url "http://llvm.org/git/clang.git", :branch => "release_35"
    end

    resource "clang-tools-extra" do
      url "http://llvm.org/git/clang-tools-extra.git", :branch => "release_35"
    end

    resource "compiler-rt" do
      url "http://llvm.org/git/compiler-rt.git", :branch => "release_35"
    end

    resource "libcxx" do
      url "http://llvm.org/git/libcxx.git", :branch => "release_35"
    end
  end

  resource "libcxxabi" do
    url "http://llvm.org/git/libcxxabi.git", :branch => "release_35"
  end if MacOS.version <= :snow_leopard

    # Use absolute paths for shared library IDs
  patch :DATA

  option :universal
  option "with-lld", "Build LLD linker"
  option "with-lldb", "Build LLDB debugger"
  option "with-rtti", "Build with C++ RTTI"
  option "with-python", "Build Python bindings against Homebrew Python"
  option "without-shared", "Don't build LLVM as a shared library"
  option "without-assertions", "Speeds up LLVM, but provides less debug information"

  deprecated_option "rtti" => "with-rtti"
  deprecated_option "disable-shared" => "without-shared"
  deprecated_option "disable-assertions" => "without-assertions"

  if MacOS.version <= :snow_leopard
    depends_on :python
  else
    depends_on :python => :optional
  end
  depends_on "cmake" => :build
  depends_on "swig" if build.with? "lldb"

  # Apple's libstdc++ is too old to build LLVM
  fails_with :gcc
  fails_with :llvm

  # version suffix
  def ver
    "3.5"
  end

  def install
    # Apple's libstdc++ is too old to build LLVM
    ENV.libcxx if ENV.compiler == :clang

    if build.with?("lldb") && build.without?("clang")
      fail "Building LLDB needs Clang support library."
    end

    (buildpath/"projects/libcxx").install resource("libcxx")
    (buildpath/"tools/clang").install resource("clang")
    (buildpath/"tools/clang/tools/extra").install resource("clang-tools-extra")
    (buildpath/"tools/lld").install resource("lld") if build.with? "lld"
    (buildpath/"tools/lldb").install resource("lldb") if build.with? "lldb"

    if build.universal?
      ENV.permit_arch_flags
      ENV["UNIVERSAL"] = "1"
      ENV["UNIVERSAL_ARCH"] = Hardware::CPU.universal_archs.join(" ")
    end

    ENV["REQUIRES_RTTI"] = "1" if build.with?("rtti") || build.with?("clang")

    args = %w[
      -DLLVM_OPTIMIZED_TABLEGEN=On
    ]

    args << "-DBUILD_SHARED_LIBS=Off" if build.without? "shared"

    args << "-DLLVM_ENABLE_ASSERTIONS=On" if build.with? "assertions"

    mktemp do
      system "cmake", "-G", "Unix Makefiles", buildpath, *(std_cmake_args + args)
      system "make"
      system "make", "install"
    end

    system "make", "-C", "projects/libcxx", "install",
      "DSTROOT=#{prefix}", "SYMROOT=#{buildpath}/projects/libcxx"

    (share/"clang/tools").install Dir["tools/clang/tools/scan-{build,view}"]
    inreplace "#{share}/clang/tools/scan-build/scan-build", "$RealBin/bin/clang", "#{bin}/clang"
    bin.install_symlink share/"clang/tools/scan-build/scan-build", share/"clang/tools/scan-view/scan-view"
    man1.install_symlink share/"clang/tools/scan-build/scan-build.1"

    # install llvm python bindings
    (lib+"python2.7/site-packages").install buildpath/"bindings/python/llvm"
    (lib+"python2.7/site-packages").install buildpath/"tools/clang/bindings/python/clang" if build.with? "clang"
  end

  test do
    system "#{bin}/llvm-config", "--version"
  end

  def caveats
    <<-EOS.undent
      LLVM executables are installed in #{opt_bin}.
      Extra tools are installed in #{opt_share}/llvm.
    EOS
  end
end

__END__
diff --git a/Makefile.rules b/Makefile.rules
index ebebc0a..b0bb378 100644
--- a/Makefile.rules
+++ b/Makefile.rules
@@ -599,7 +599,12 @@ ifneq ($(HOST_OS), $(filter $(HOST_OS), Cygwin MingW))
 ifneq ($(HOST_OS),Darwin)
   LD.Flags += $(RPATH) -Wl,'$$ORIGIN'
 else
-  LD.Flags += -Wl,-install_name  -Wl,"@rpath/lib$(LIBRARYNAME)$(SHLIBEXT)"
+  LD.Flags += -Wl,-install_name
+  ifdef LOADABLE_MODULE
+    LD.Flags += -Wl,"$(PROJ_libdir)/$(LIBRARYNAME)$(SHLIBEXT)"
+  else
+    LD.Flags += -Wl,"$(PROJ_libdir)/$(SharedPrefix)$(LIBRARYNAME)$(SHLIBEXT)"
+  endif
 endif
 endif
 endif
