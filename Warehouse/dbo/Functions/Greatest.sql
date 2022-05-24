CREATE FUNCTION [dbo].[Greatest](@Value1 INT, @Value2 INT)
RETURNS INT
AS
BEGIN
  IF @Value1 > @Value2
    RETURN @Value1
  RETURN ISNULL(@Value2, @Value1)
END