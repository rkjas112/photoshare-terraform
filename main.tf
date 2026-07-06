resource "aws_vpc" "photoshare" {
  cidr_block = "10.0.0.0/16"

  tags = { Name = "photoshare-vpc"
  }
}

resource "aws_subnet" "public_1" {
  cidr_block        = "10.0.1.0/24"
  vpc_id            = aws_vpc.photoshare.id
  availability_zone = "ap-south-1a"
  tags = { Name = "Public Subnet 1"
  }
}

resource "aws_subnet" "private_1" {
  cidr_block        = "10.0.2.0/24"
  vpc_id            = aws_vpc.photoshare.id
  availability_zone = "ap-south-1a"
  tags = { Name = "Private Subnet 1"
  }
}

resource "aws_subnet" "public_2" {
  cidr_block        = "10.0.3.0/24"
  vpc_id            = aws_vpc.photoshare.id
  availability_zone = "ap-south-1b"
  tags = { Name = "Public Subnet 2"
  }
}

resource "aws_subnet" "private_2" {
  cidr_block        = "10.0.4.0/24"
  vpc_id            = aws_vpc.photoshare.id
  availability_zone = "ap-south-1b"
  tags = { Name = "Private Subnet 2"
  }
}

