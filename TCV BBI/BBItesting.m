% This program tests the BBI code.
ref = [0.0650000000;0.0707000000;0.0709830000];
days = [68;75;82;89;5;12;19;26;33;40;47;54;61];
fv = [4599097;4590987;4595705;4782951;4678551;4646588;4599276;4632012;4590717;4587825;4598925;4620371;4593062];
R = BBI(ref,days,fv)
