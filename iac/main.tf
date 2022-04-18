resource "aws_vpc" "main_vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true

  tags = {
    Name = "Test_VPC"
  }
}

resource "aws_internet_gateway" "main_ig" {
  vpc_id     = aws_vpc.main_vpc.id
  depends_on = [aws_vpc.main_vpc]

  tags = {
    Name = "main-ig"
  }
}

resource "aws_route" "to_ig" {
  route_table_id         = aws_vpc.main_vpc.main_route_table_id
  gateway_id             = aws_internet_gateway.main_ig.id
  destination_cidr_block = "0.0.0.0/0"
}

resource "aws_subnet" "eu_central_1a_sn" {
  vpc_id            = aws_vpc.main_vpc.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "eu-central-1a"
}

resource "aws_subnet" "eu_central_1b_sn" {
  vpc_id            = aws_vpc.main_vpc.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = "eu-central-1b"
}

resource "aws_route_table_association" "eu_central_1a_route" {
  subnet_id      = aws_subnet.eu_central_1a_sn.id
  route_table_id = aws_vpc.main_vpc.main_route_table_id
}

resource "aws_route_table_association" "eu_central_1b_route" {
  subnet_id      = aws_subnet.eu_central_1b_sn.id
  route_table_id = aws_vpc.main_vpc.main_route_table_id
}

resource "aws_security_group" "sg_rds" {
  name        = "sg_for_rds"
  description = "Security group for RDS"
  vpc_id      = aws_vpc.main_vpc.id

  ingress {
    description = "Allow inbound PostgreSQL traffic"
    from_port   = 0
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "Allow outbound PostgreSQL traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    "Name" = "sg-for-rds"
  }
}

resource "aws_db_subnet_group" "main_db_sg" {
  name       = "db_sg"
  subnet_ids = [aws_subnet.eu_central_1a_sn.id, aws_subnet.eu_central_1b_sn.id]
}

resource "aws_db_instance" "testdb" {
  identifier             = var.rds["name"]
  engine                 = "postgres"
  instance_class         = "db.t3.micro"
  publicly_accessible    = true
  db_subnet_group_name   = aws_db_subnet_group.main_db_sg.name
  db_name                = var.rds.name
  username               = var.rds["user"]
  password               = var.rds["pass"]
  allocated_storage      = 5
  max_allocated_storage  = 0
  storage_type           = "gp2"
  vpc_security_group_ids = [aws_security_group.sg_rds.id]
  skip_final_snapshot    = true
  depends_on             = [aws_security_group.sg_rds, aws_db_subnet_group.main_db_sg]

  tags = {
    Name = "Test_DB"
  }
}


output "db_endpoint" {
  value       = aws_db_instance.testdb.address
  description = "RDS Postgres database address"
  depends_on  = [aws_db_instance.testdb]
}
