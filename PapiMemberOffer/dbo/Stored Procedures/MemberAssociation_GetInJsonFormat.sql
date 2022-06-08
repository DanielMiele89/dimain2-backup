-- ====================================================================================
-- Author:		Rajshikha Jain
-- Create date: 2016-01-05
-- Description:	Create json formatted output from the MemberAssociation table
-- jira Ticket: ROC-97
-- =====================================================================================

CREATE PROCEDURE [MemberAssociation_GetInJsonFormat]
	 @Chunk INT 
	, @MemberCount INT
	, @PrevPage INT
	, @NextPage INT
	, @TotalPages INT
	, @FileDate VARCHAR(10)
	
AS

SET NOCOUNT ON

DECLARE  @FileHeader VARCHAR(MAX)
, @JsonOut VARCHAR(MAX)
 
select @FileHeader = '{' + CHAR(13) + 
                     SPACE(4) + '"totalresults":' + Convert(Varchar(20), @MemberCount) + ',' + CHAR(13) +
					 SPACE(4) + '"totalpages":' + Convert(Varchar(10), @TotalPAges) + ',' + CHAR(13) +
					 SPACE(4) + '"page": ' + Convert(Varchar(10), @Chunk) + ',' + CHAR(13) +
					 SPACE(4) + '"_links": {' + CHAR(13) +
					 SPACE(8) + '"self": {' + CHAR(13) +
					 SPACE(12) + '"href": "/api/memberoffers?date=' + @FileDate + '&page=' + Convert(Varchar(10), @Chunk) + '"' + CHAR(13) +
					 SPACE(8) + '},' + CHAR(13) + 
					 
					 CASE WHEN @PrevPage <> 0 THEN 
					 SPACE(12) + '"prev":{' + CHAR(13)  +
					 SPACE(12) + '"href":"/api/memberoffers?date=' + @FileDate + '&page=' + Convert(Varchar(10), @PrevPage) + '"' + CHAR(13) +
					 SPACE(8) + '},' + CHAR(13) 
					 ELSE '' END + 

					 CASE WHEN @NextPage <> 0 THEN 
					 SPACE(12) + '"next":{' + CHAR(13)  +
					 SPACE(12) + '"href":"/api/memberoffers?date=' + @FileDate + '&page=' + Convert(Varchar(10), @NextPage) + '"' + CHAR(13) +
					 SPACE(8) + '},' + CHAR(13) 
					 ELSE '' END + 

					 SPACE(12) + '"page": {' + CHAR(13) + 
					 SPACE(12) + '"href": "/api/memberoffers?date={date}&page={page}",' + CHAR(13) + 
					 SPACE(12) + '"templated": true' + CHAR(13) + 
					 SPACE(8) + '}' + CHAR(13) + 
					 SPACE(4) + '},' + CHAR(13) +

					 SPACE(4) + '"_embedded": {' + CHAR(13) +
					 SPACE(8) + '"members": '

;WITH CleanData AS (
       SELECT 
              SourceUID = 
                     REPLACE( --escape tab properly within a value
                     REPLACE( --escape return properly
                     REPLACE( --linefeed must be escaped
                     REPLACE( --backslash too
                     REPLACE( --forwardslash
                     CAST(SourceUID AS NVARCHAR(50)),
                     '\', '\\'), '/', '\/'), CHAR(10),'\n'), CHAR(13),'\r'), CHAR(09),'\t'),

              OfferID = 
                     REPLACE( --escape tab properly within a value
                     REPLACE( --escape return properly
                     REPLACE( --linefeed must be escaped
                     REPLACE( --backslash too
                     REPLACE( --forwardslash
                     CAST(OfferID AS NVARCHAR(50)),
                     '\', '\\'), '/', '\/'), CHAR(10),'\n'), CHAR(13),'\r'), CHAR(09),'\t'),

              PartnerName = 
                     REPLACE( --escape tab properly within a value
                     REPLACE( --escape return properly
                     REPLACE( --linefeed must be escaped
                     REPLACE( --backslash too
                     REPLACE( --forwardslash
                     CAST(PartnerName AS NVARCHAR(50)),
                     '\', '\\'), '/', '\/'), CHAR(10),'\n'), CHAR(13),'\r'), CHAR(09),'\t') ,
			  StartDate = 
                     REPLACE( --escape tab properly within a value
                     REPLACE( --escape return properly
                     REPLACE( --linefeed must be escaped
                     REPLACE( --backslash too
                     REPLACE( --forwardslash
                     ISNULL(CONVERT(VARCHAR(24),StartDate,121),'null'),
                     '\', '\\'), '/', '\/'), CHAR(10),'\n'), CHAR(13),'\r'), CHAR(09),'\t') ,
			  EndDate = 
                     REPLACE( --escape tab properly within a value
                     REPLACE( --escape return properly
                     REPLACE( --linefeed must be escaped
                     REPLACE( --backslash too
                     REPLACE( --forwardslash
                     ISNULL(CONVERT(VARCHAR(24),EndDate,121),'null'),
                     '\', '\\'), '/', '\/'), CHAR(10),'\n'), CHAR(13),'\r'), CHAR(09),'\t') ,

       
              rn = ROW_NUMBER() OVER(ORDER BY (SELECT SourceUID)),
              rc = COUNT(*) OVER(PARTITION BY 1),
              rns = ROW_NUMBER() OVER(PARTITION BY SourceUID ORDER BY (SELECT NULL)),
              rcs = COUNT(*) OVER(PARTITION BY SourceUID)
     		 FROM MemberOfferAssociation WHERE Chunk = @Chunk 
),
SingleRows AS (
       SELECT 
              rn, rc, 
              rns, rcs,
              SourceUID, 
                     
              SingleRow = CASE WHEN c.rns = 1 THEN 
                     SPACE(12) + '{' + CHAR(13) + 
                     SPACE(16) + '"suid":' + '"' + CAST(SourceUID AS varchar(26)) + '",' + CHAR(13) + 
                     SPACE(16) + '"_embedded": {' + CHAR(13) + 
                     SPACE(20) + '"offers": [' + CHAR(13) 
                     ELSE '' END + 
        
               SPACE(24) + '{' + CHAR(13) + 
               SPACE(28) + '"offerid":' + ' ' + CAST(OfferID AS varchar(10)) + ',' + CHAR(13) + 
               SPACE(28) + '"partnername":' + '"' + PartnerName + '",' + CHAR(13) + 
			   SPACE(28) + '"startdate":' + CASE Startdate WHEN 'null' THEN 'null'
			                                ELSE '"' + StartDate + '"' END + ',' + CHAR(13) + 
			   SPACE(28) + '"enddate":' + CASE EndDate WHEN 'null' THEN 'null'
			                             ELSE '"' + EndDate + '"' END + CHAR(13) + 
               SPACE(24) + '}' + CASE WHEN rns < rcs THEN ',' ELSE '' END + CHAR(13) + 

              CASE WHEN c.rns = rcs THEN 
                     SPACE(20) + ']' + CHAR(13) + 
                     SPACE(16) + '}' + CHAR(13) + 
                     SPACE(12) + '}'   
                     ELSE '' END + CASE WHEN c.rns = rcs and rn < rc THEN ',' ELSE '' END +  CHAR(13) --+ 
              
       FROM CleanData c
)

SELECT JsonOut = @FileHeader + CAST(CASE WHEN rc > 0 THEN '[' + CHAR(13) + x.JSON +  SPACE(8) + ']' + CHAR(13) +  SPACE(4) +  '}' + CHAR(13) + '}'
							ELSE '' END AS varchar(MAX))
FROM (Select rc= 1) s
CROSS APPLY (
       SELECT JSON = (
              SELECT SingleRow 
              FROM SingleRows
			  ORDER BY rn
              FOR XML PATH(''),TYPE).value('.','NVARCHAR(MAX)'
              )
) x

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[MemberAssociation_GetInJsonFormat] TO [GAS]
    AS [dbo];

