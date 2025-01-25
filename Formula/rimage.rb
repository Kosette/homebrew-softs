class Rimage < Formula
  desc "A tool for resizing images in bulk"
  homepage "https://github.com/SalOne22/rimage"
  version "0.10.3"
  license "MIT"

  if Hardware::CPU.intel?
    url "https://github.com/SalOne22/rimage/releases/download/v0.10.3/rimage-0.10.3-x86_64-apple-darwin.tar.gz"
    sha256 "48d2605b9ac5bd57a8c895f3b9631b48642dc9ad3ffbf1a76503720a36fc9da0"
  elsif Hardware::CPU.arm?
    url "https://github.com/SalOne22/rimage/releases/download/v0.10.3/rimage-0.10.3-aarch64-apple-darwin.tar.gz"
    sha256 "c70ede263ea0486000aab8f57f1c8d3a82315f0cd4dda51fbd9c6dc81daabcdb"
  end

  def install
    bin.install "rimage"
  end

  test do
    system "#{bin}/rimage", "--version"
  end
end

