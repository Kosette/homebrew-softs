class Rimage < Formula
  desc "A tool for resizing images in bulk"
  homepage "https://github.com/SalOne22/rimage"
  version "0.10.2"
  license "MIT"

  if Hardware::CPU.intel?
    url "https://github.com/SalOne22/rimage/releases/download/v0.10.2/rimage-0.10.2-x86_64-apple-darwin.tar.gz"
    sha256 "a68ce9b168d6af39e510612b402957e1cfff9ce9831e20803d5d2d43b23a344b"
  elsif Hardware::CPU.arm?
    url "https://github.com/SalOne22/rimage/releases/download/v0.10.2/rimage-0.10.2-aarch64-apple-darwin.tar.gz"
    sha256 "6657b48f65e28eb18a81f622e505df1e6f5630eca1289b7ec4d14e712c558056"
  end

  def install
    bin.install "rimage"
  end

  test do
    system "#{bin}/rimage", "--version"
  end
end

