CREATE FUNCTION [dbo].[FuzzyMatch_iTVF2k5] 
   (@Reference VARCHAR(100) = NULL,
   @Target VARCHAR(100) = NULL)
RETURNS table WITH SCHEMABINDING 
AS
-- Chris Morris 2012 
-- Fuzzy-matching using tokens
-- See also http://research.microsoft.com/pubs/75996/bm_sigmod03.pdf

RETURN 
SELECT 
   d.Method, 
   MatchRatio = CAST(CASE 
      WHEN d.Method = 1 THEN 100
      WHEN d.Method = 3 THEN [d].[LenTarget]*100.00/[d].[LenReference]
      WHEN d.Method = 4 THEN [d].[LenReference]*100.00/[d].[LenTarget]
 
      WHEN d.Method = 5 THEN
         (
         SELECT 
            MatchPC = (100.00 * ISNULL(NULLIF(SUM(
                  CASE WHEN Tally.n < [x].[PosInTarget] THEN Tally.n/[x].[PosInTarget] ELSE [x].[PosInTarget]/Tally.n END
                           ),0)+2.00,0) / LenReference) 
                  * CASE WHEN LenTarget > LenReference THEN LenReference/LenTarget ELSE 1.00 END    
         FROM ( -- Tally
            SELECT TOP (CAST(LenReference AS INT)-2) n = ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) 
            FROM (SELECT n FROM (VALUES (1),(1),(1),(1),(1),(1),(1),(1),(1),(1)) d (n)) a, 
            (SELECT n FROM (VALUES (1),(1),(1),(1),(1),(1),(1),(1),(1),(1)) d (n)) b
            ) Tally 
         CROSS APPLY (SELECT PosInTarget = 1.0*CHARINDEX(SUBSTRING(@Reference, Tally.n, 3), @Target)) x
         )

      WHEN d.Method = 6 THEN        
         (
         SELECT
            MatchPC = (100.00 * ISNULL(NULLIF(SUM(
                  CASE WHEN Tally.n < [x].[PosInTarget] THEN Tally.n/[x].[PosInTarget] ELSE [x].[PosInTarget]/Tally.n END
                           ),0)+1.00,0) / LenReference)  
                  * CASE WHEN LenTarget > LenReference THEN LenReference/LenTarget ELSE 1.00 END
         FROM ( -- Tally
            SELECT TOP (CAST(LenReference AS INT)-1) n = ROW_NUMBER() OVER (ORDER BY (SELECT NULL))  
            FROM (VALUES (1),(1),(1),(1),(1),(1),(1),(1),(1),(1)) d (n)
         ) Tally
         CROSS APPLY (SELECT PosInTarget = 1.0*CAST(CHARINDEX(SUBSTRING(@Reference, Tally.n, 2), @Target) AS DECIMAL(5,2))) x
         ) 
      ELSE NULL      
      END AS DECIMAL(5,2)) 
      
FROM (
   SELECT Method = CASE
      WHEN @Reference = @Target THEN 1
      WHEN @Reference IS NULL OR @Target IS NULL THEN 2
      WHEN @Reference LIKE '%'+@Target+'%' THEN 3
      WHEN @Target LIKE '%'+@Reference+'%' THEN 4
      WHEN DATALENGTH(@Reference) >= 7 AND DATALENGTH(@Target) >= 7 THEN 5 
      WHEN DATALENGTH(@Reference) > 2 AND DATALENGTH(@Target) > 2 THEN 6 
      ELSE 7      
      END,
   LenTarget = CAST(DATALENGTH(@Target) AS DECIMAL(5,2)),
   LenReference = CAST(DATALENGTH(@Reference) AS DECIMAL(5,2))
) d   