CREATE TABLE [dbo].[FanCredentials] (
    [ID]                         INT            IDENTITY (1, 1) NOT FOR REPLICATION NOT NULL,
    [FanID]                      INT            NOT NULL,
    [HashedPassword]             NVARCHAR (128) NOT NULL,
    [OnlineRegistrationDate]     DATETIME       NULL,
    [HideFirstTimeSSOLogin]      BIT            NULL,
    [OnlineRegistrationSourceID] INT            NULL,
    CONSTRAINT [PK_FanCredentials] PRIMARY KEY CLUSTERED ([ID] ASC)
);

