/************************************************************************
Author:     Hayden Reid
Date:       2018-06-28
Purpose:    Generates HTML for a data dictionary based on extended properties
            held in the tables on the database
Copyright, MavOps LTD 2018, All rights reserved.
------------------------------------------------------------------------
Change log
DD/MM/YYYY  Name of changer
            Description of modification
*************************************************************************/
CREATE PROCEDURE Processing.[Documentation_DataDictionary_FetchAsConfluence](
    @Introduction VARCHAR(1000) = ''
  , @PrimaryHeaderColour VARCHAR(10) = '#60295f'
  , @SecondaryHeaderColour VARCHAR(10) = '#4f2f4e'
  , @PrimaryRowColour VARCHAR(10) = '#FFFFFF'
  , @SecondaryRowColour VARCHAR(10) = '#DCDCDC'
  , @shouldHeaderFontBeWhite BIT = 1
  , @shouldExcerptIntroduction BIT = 1
  , @ProcessName VARCHAR(1000) = 'Client Data Pipeline'
)
AS
BEGIN
    /*****************************************************************
        USER VARIABLES
    *****************************************************************/
    /*****************************************************************
        SYSTEM VARIABLES
    *****************************************************************/
    DECLARE @Table VARCHAR(MAX)
    SET @Table = ''
    DECLARE @HTML VARCHAR(MAX)
    SET @HTML = ''
    DECLARE @Cnt INT = 1
          , @Max INT
    /*****************************************************************
        PROCESS
    *****************************************************************/
    SET NOCOUNT ON
    IF OBJECT_ID('tempdb..#TableIds') IS NOT NULL
        DROP TABLE #TableIds
    SELECT
        major_id
    INTO #TableIds
    FROM sys.extended_properties
    WHERE name = 'Related_Process'
        AND minor_id = 0
        AND value = @ProcessName
    --------------------------------------------------------------------- 
    -- Table to hold the tables columns that have extended properties 
    -- to loop through
    ---------------------------------------------------------------------
    IF OBJECT_ID('tempdb..#ExtendedTables') IS NOT NULL
        DROP TABLE #ExtendedTables
    CREATE TABLE #ExtendedTables
    (
        id          INT IDENTITY (1, 1)
      , SchemaName  SYSNAME
      , TableName   SYSNAME
      , [object_id] INT
      , [schema_id] INT
    )
    INSERT INTO #ExtendedTables
     SELECT DISTINCT
         S.name SchemaName
       , O.name TableName
       , O.object_id
       , S.schema_id
     FROM sys.extended_properties EP
     JOIN #TableIds ti
         ON ti.major_id = EP.major_id
     JOIN sys.all_objects O
         ON EP.major_id = O.object_id
             AND EP.class <> 3
     JOIN sys.schemas S
         ON (EP.class <> 3
                 AND O.schema_id = S.schema_id)
             OR (EP.class = 3
                 AND EP.major_id = S.schema_id)
     JOIN sys.columns AS c
         ON EP.major_id = c.object_id
             AND EP.minor_id = c.column_id
     WHERE EP.name <> 'microsoft_database_tools_support'
         AND O.object_id IS NOT NULL
         AND c.object_id IS NOT NULL
     ORDER BY s.schema_id
            , o.name -- Order result set so that the data can be 
    -- searched easier once the data dictionary has been generated
    --------------------------------------------------------------------- 
    -- Create the top of the HTML code including stylesheet
    -- also includes the Title and Subtitle of the data dictionary
    ---------------------------------------------------------------------
    DECLARE @ExcerptMacroTemplate VARCHAR(MAX) = '
<ac:structured-macro ac:name="excerpt" ac:schema-version="1" data-layout="default"
    ac:macro-id="a9f19883-1a20-406a-9e01-a92d0c4ad897">
    <ac:rich-text-body>
        <p>#Introduction#</p>
    </ac:rich-text-body>
</ac:structured-macro>'
          , @NoExcerptMacroTemplate VARCHAR(MAX) = '
<p>#Introduction#</p>'
    DECLARE @HeaderTagStart VARCHAR(100) = CASE
                WHEN @shouldHeaderFontBeWhite = 1
                 THEN '<p><span style="color: rgb(255,255,255);">'
                ELSE '<p>'
            END
          , @HeaderTagEnd VARCHAR(100) = CASE
                WHEN @shouldHeaderFontBeWhite = 1
                 THEN '</span></p>'
                ELSE '</p>'
            END
          , @IntroductionHTML VARCHAR(MAX) = CASE
                WHEN @shouldExcerptIntroduction = 1
                 THEN @ExcerptMacroTemplate
                ELSE @NoExcerptMacroTemplate
            END
    SET @HTML = REPLACE(@IntroductionHTML, '#Introduction#', @Introduction) + '
<ac:structured-macro ac:name="toc" ac:schema-version="1" data-layout="default"
ac:macro-id="7e8ddd9b-10ad-43d2-b06b-08ca8e4505ae" />
'
    --------------------------------------------------------------------- 
    -- Create table definition to be used for each table
    ---------------------------------------------------------------------
    SET @Table += '
<h1>#TableName#</h1>
<p>#Description#</p>
<table data-layout="full-width">
    <colgroup>
        <col style="width: 345.0px;" />
        <col style="width: 421.0px;" />
        <col style="width: 152.0px;" />
        <col style="width: 115.0px;" />
        <col style="width: 115.0px;" />
        <col style="width: 115.0px;" />
        <col style="width: 115.0px;" />
        <col style="width: 115.0px;" />
        <col style="width: 127.0px;" />
        <col style="width: 127.0px;" />
    </colgroup>
    <tbody>
        <tr>
            <th data-highlight-colour="' + @PrimaryHeaderColour + '">
                ' + @HeaderTagStart + 'Column Name' + @HeaderTagEnd + '
            </th>
            <th data-highlight-colour="' + @SecondaryHeaderColour + '">
                ' + @HeaderTagStart + 'Description' + @HeaderTagEnd + '
            </th>
            <th data-highlight-colour="' + @PrimaryHeaderColour + '">
                ' + @HeaderTagStart + 'InPrimaryKey' + @HeaderTagEnd + '
            </th>
            <th data-highlight-colour="' + @SecondaryHeaderColour + '">
                ' + @HeaderTagStart + 'DataType' + @HeaderTagEnd + '
            </th>
            <th data-highlight-colour="' + @PrimaryHeaderColour + '">
                ' + @HeaderTagStart + 'Length' + @HeaderTagEnd + '
            </th>
            <th data-highlight-colour="' + @SecondaryHeaderColour + '">
                ' + @HeaderTagStart + 'Numeric Precision' + @HeaderTagEnd + '
            </th>
            <th data-highlight-colour="' + @PrimaryHeaderColour + '">
                ' + @HeaderTagStart + 'Numeric Scale' + @HeaderTagEnd + '
            </th>
            <th data-highlight-colour="' + @SecondaryHeaderColour + '">
                ' + @HeaderTagStart + 'Nullable' + @HeaderTagEnd + '
            </th>
            <th data-highlight-colour="' + @PrimaryHeaderColour + '">
                ' + @HeaderTagStart + 'isIdentity' + @HeaderTagEnd + '
            </th>
            <th data-highlight-colour="' + @SecondaryHeaderColour + '">
                ' + @HeaderTagStart + 'Default Value' + @HeaderTagEnd + '
            </th>
        </tr>
'
    --------------------------------------------------------------------- 
    -- Output the top of the HTML
    ---------------------------------------------------------------------
    PRINT @HTML
    SELECT
        REPLACE
        (
        REPLACE(@Table, '#TableName#', QUOTENAME(et.SchemaName) + '.' + QUOTENAME(et.TableName)) -- Inserts table name to top of table
        , '#Description#', ISNULL(CAST(ex.value AS VARCHAR(1000)), '') -- Inserts description of table (where applicable) underneath title
        ) +
        (
            SELECT
                CASE
                    WHEN Ordinal % 2 = 1
                     THEN REPLACE(htmlString, '#RowColour#', @PrimaryRowColour)
                    ELSE REPLACE(htmlString, '#RowColour#', @SecondaryRowColour)
                END
            FROM (
                SELECT
                    '<tr>'
                    + '<td data-highlight-colour="#RowColour#"><p>' + CAST(clmns.name AS VARCHAR(35)) + '</p></td>' -- ColumnName
                    + '<td data-highlight-colour="#RowColour#"><p>' + ISNULL(CAST(exprop.value AS VARCHAR(2000)), '') + '</p></td>' -- Description
                    + '<td data-highlight-colour="#RowColour#"><p>' + ISNULL(CAST(idxcol.index_column_id AS VARCHAR(20)), 'NO') + '</p></td>' -- InPrimaryKey
                    + '<td data-highlight-colour="#RowColour#"><p>' + CAST(udt.name AS CHAR(15)) + '</p></td>' -- DataType
                    + '<td data-highlight-colour="#RowColour#"><p>' + CAST(CAST(CASE
                        WHEN typ.name IN (N'nchar', N'nvarchar')
                            AND clmns.max_length <> -1
                         THEN clmns.max_length / 2
                        ELSE clmns.max_length
                    END
                    AS INT)
                    AS VARCHAR(20)) + '</p></td>' -- Length
                    + '<td data-highlight-colour="#RowColour#"><p>' + CAST(CAST(clmns.precision AS INT) AS VARCHAR(20)) + '</p></td>' -- NumericPrecision
                    + '<td data-highlight-colour="#RowColour#"><p>' + CAST(CAST(clmns.scale AS INT) AS VARCHAR(20)) + '</p></td>' -- NumericScale
                    + '<td data-highlight-colour="#RowColour#"><p>' + CAST(CASE
                        WHEN clmns.is_nullable = 1
                         THEN 'TRUE'
                        ELSE 'FALSE'
                    END AS VARCHAR(20)) + '</p></td>'  -- Nullable
                    + '<td data-highlight-colour="#RowColour#"><p>' + CAST(CASE
                        WHEN clmns.is_identity = 1
                         THEN 'TRUE'
                        ELSE 'FALSE'
                    END AS VARCHAR(20)) + '</p></td>'  -- Identity
                    + '<td data-highlight-colour="#RowColour#"><p>' + ISNULL(CAST(cnstr.definition AS VARCHAR(20)), '') + '</p></td>' -- DefaultValue
                    + '</tr>'
                  , ROW_NUMBER() OVER (ORDER BY clmns.column_id)
                FROM sys.tables tbl
                JOIN sys.all_columns clmns
                    ON clmns.object_id = tbl.object_id
                LEFT JOIN sys.indexes idx
                    ON idx.object_id = clmns.object_id
                        AND idx.is_primary_key = 1
                LEFT JOIN sys.index_columns idxcol
                    ON idxcol.index_id = idx.index_id
                        AND idxcol.column_id = clmns.column_id
                        AND idxcol.object_id = clmns.object_id
                        AND idxcol.is_included_column = 0
                LEFT JOIN sys.types udt
                    ON udt.user_type_id = clmns.user_type_id
                LEFT JOIN sys.types typ
                    ON typ.user_type_id = clmns.system_type_id
                        AND typ.user_type_id = typ.system_type_id
                LEFT JOIN sys.default_constraints cnstr
                    ON cnstr.object_id = clmns.default_object_id
                LEFT JOIN sys.extended_properties exprop
                    ON exprop.major_id = clmns.object_id
                        AND exprop.minor_id = clmns.column_id
                WHERE tbl.object_id = et.object_id
                    AND exprop.name = 'MS_Description'
            ) x (htmlString, Ordinal)
            ORDER BY X.Ordinal ASC
            FOR XML PATH (''), TYPE
        )
        .value('.', 'varchar(max)')
        + '</tbody></table>'
    FROM #ExtendedTables et
    LEFT JOIN sys.extended_properties ex
        ON ex.major_id = et.object_id
            AND ex.minor_id = 0
            AND ex.name = 'MS_Description'
END