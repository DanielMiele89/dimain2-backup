CREATE TABLE [Staging].[PostSFDEmailEvaluation_CJStageCounts] (
    [Tablename]     VARCHAR (200) NULL,
    [DataDate]      DATE          NULL,
    [LionSendID]    INT           NULL,
    [ClubID]        SMALLINT      NULL,
    [Shortcode]     VARCHAR (2)   NULL,
    [Pending]       VARCHAR (25)  NULL,
    [Available]     VARCHAR (25)  NULL,
    [CustomerCount] INT           NULL,
    [Problem]       CHAR (3)      NULL
);

