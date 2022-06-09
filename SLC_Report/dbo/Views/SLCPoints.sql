CREATE VIEW [dbo].[SLCPoints]
AS
SELECT  [ID]
      ,[CategoryID]
      ,[Description]
      ,[Points]
      ,[Status]
      ,[ClubAPI]
  FROM [SLC_REPL].[dbo].[SLCPoints]