CREATE TABLE [dbo].[CRT_File] (
    [ID]               INT            IDENTITY (1, 1) NOT FOR REPLICATION NOT NULL,
    [Filename]         VARCHAR (100)  NOT NULL,
    [MatcherShortName] CHAR (3)       NOT NULL,
    [FileType]         CHAR (3)       NOT NULL,
    [FileDirection]    VARCHAR (10)   NOT NULL,
    [VectorID]         INT            NOT NULL,
    [VectorMajorID]    INT            NOT NULL,
    [ProcessStart]     DATETIME       NOT NULL,
    [ProcessEnd]       DATETIME       NULL,
    [Status]           TINYINT        NULL,
    [RecordCount]      INT            NULL,
    [StatusDetail]     VARCHAR (4000) NULL,
    CONSTRAINT [PK_CRT_File] PRIMARY KEY CLUSTERED ([ID] ASC)
);


GO
GRANT SELECT
    ON OBJECT::[dbo].[CRT_File] TO [PII_Removed]
    AS [dbo];

