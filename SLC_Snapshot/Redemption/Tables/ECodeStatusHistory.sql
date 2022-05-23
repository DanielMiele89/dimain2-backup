CREATE TABLE [Redemption].[ECodeStatusHistory] (
    [ECodeID]          INT      NOT NULL,
    [Status]           TINYINT  NOT NULL,
    [StatusChangeDate] DATETIME NOT NULL,
    [ChangedBy]        INT      NOT NULL,
    [ChangeSourceType] TINYINT  NOT NULL,
    CONSTRAINT [PK_ECodeStatusHistory_EcodeID_Status_StatusChangeDate] PRIMARY KEY CLUSTERED ([ECodeID] ASC, [Status] ASC, [StatusChangeDate] ASC)
);

