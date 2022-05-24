CREATE TABLE [SmartEmail].[PostSFDUploadValidation_DataChecks] (
    [TableName]          VARCHAR (50) NULL,
    [noRows]             INT          NULL,
    [TableName2]         VARCHAR (50) NULL,
    [noRowsMatched]      INT          NULL,
    [RunDateTime]        DATETIME     NULL,
    [RunID]              INT          NOT NULL,
    [SmartEmail]         BIT          NULL,
    [LionSendID]         INT          NULL,
    [isAngela]           BIT          DEFAULT ((0)) NULL,
    [isMarianneRBS]      BIT          DEFAULT ((0)) NOT NULL,
    [isMariannePersonal] BIT          DEFAULT ((0)) NOT NULL
);


GO
CREATE CLUSTERED INDEX [CIX_SFDDataChecks_RunIDTable]
    ON [SmartEmail].[PostSFDUploadValidation_DataChecks]([RunID] ASC, [TableName] ASC);

