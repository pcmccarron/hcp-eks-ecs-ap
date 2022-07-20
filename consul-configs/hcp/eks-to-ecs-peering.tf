resource "aws_vpc_peering_connection" "eks-to-ecs" {
    peer_vpc_id = module.vpc.vpc_id
    vpc_id = module.eks-vpc.vpc_id
}


resource "aws_vpc_peering_connection_accepter" "eks-to-ecs-peer" {
  vpc_peering_connection_id = aws_vpc_peering_connection.eks-to-ecs.id
  auto_accept               = true
}

resource "aws_route" "eks-to-ecs-peering" {
  route_table_id            = module.eks-vpc.public_route_table_ids[0]
  destination_cidr_block    = module.vpc.vpc_cidr_block
  vpc_peering_connection_id = aws_vpc_peering_connection_accepter.eks-to-ecs-peer.vpc_peering_connection_id
}

resource "aws_route" "eks-to-ecs-peering2" {
  route_table_id            = module.eks-vpc.private_route_table_ids[0]
  destination_cidr_block    = module.vpc.vpc_cidr_block
  vpc_peering_connection_id = aws_vpc_peering_connection_accepter.eks-to-ecs-peer.vpc_peering_connection_id
}

resource "aws_route" "ecs-to-eks-peering" {
  count = length(module.vpc.public_route_table_ids)

  route_table_id            = module.vpc.public_route_table_ids[count.index]
  destination_cidr_block    = module.eks-vpc.vpc_cidr_block
  vpc_peering_connection_id = aws_vpc_peering_connection_accepter.eks-to-ecs-peer.vpc_peering_connection_id
}

resource "aws_route" "ecs-to-eks-peering2" {
  count = length(module.vpc.private_route_table_ids)

  route_table_id            = module.vpc.private_route_table_ids[count.index]
  destination_cidr_block    = module.eks-vpc.vpc_cidr_block
  vpc_peering_connection_id = aws_vpc_peering_connection_accepter.eks-to-ecs-peer.vpc_peering_connection_id
}