# security group for bastion, to allow access into the bastion host from your IP
resource "aws_security_group" "bastion_sg" {
  name        = "bastion_sg"
  vpc_id      = module.vpc.vpc_id
  description = "Allow incoming ssh connections."

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "Bastion-SG"
  }
}


# security group for instances, to have access only from the internal load balancer and bastion instance
resource "aws_security_group" "instance-sg" {
  name   = "webserver-sg"
  vpc_id = module.vpc.vpc_id
  ingress {
    description     = "Allow traffic from bastion"
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = [aws_security_group.bastion_sg.id]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "instance-sg"
  }

}
# security group for datalayer to alow traffic from websever on  mysql port 
resource "aws_security_group" "datalayer-sg" {
  name   = "datalayer-sg"
  vpc_id = module.vpc.vpc_id

  ingress {
    description     = "Allow traffic from instance to database "
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.instance-sg.id]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "datalayer-sg"
  }
}