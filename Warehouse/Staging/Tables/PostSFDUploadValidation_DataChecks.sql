CREATE TABLE [Staging].[PostSFDUploadValidation_DataChecks] (
    [TableName]          VARCHAR (50) NULL,
    [noRows]             INT          NULL,
    [TableName2]         VARCHAR (50) NULL,
    [noRowsMatched]      INT          NULL,
    [isAngela]           BIT          DEFAULT ((0)) NULL,
    [RunDateTime]        DATETIME     NULL,
    [RunID]              INT          NOT NULL,
    [SmartEmail]         BIT          NULL,
    [LionSendID]         INT          NULL,
    [isMarianneRBS]      BIT          DEFAULT ((0)) NOT NULL,
    [isMariannePersonal] BIT          DEFAULT ((0)) NOT NULL
);


GO
CREATE CLUSTERED INDEX [idx_RunID]
    ON [Staging].[PostSFDUploadValidation_DataChecks]([RunID] ASC);

