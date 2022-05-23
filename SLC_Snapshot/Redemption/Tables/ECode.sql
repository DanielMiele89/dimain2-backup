CREATE TABLE [Redemption].[ECode] (
    [ID]                     INT             IDENTITY (1, 1) NOT FOR REPLICATION NOT NULL,
    [RedeemID]               INT             NOT NULL,
    [BatchID]                INT             NOT NULL,
    [Status]                 TINYINT         NOT NULL,
    [StatusChangeDate]       DATETIME        NOT NULL,
    [TransID]                INT             NULL,
    [EncryptedEcode]         VARBINARY (618) NOT NULL,
    [ReturnedToRetailerDate] DATE            NULL,
    CONSTRAINT [PK_ECode_ID] PRIMARY KEY CLUSTERED ([ID] ASC)
);


GO
ALTER TABLE [Redemption].[ECode] SET (LOCK_ESCALATION = DISABLE);

