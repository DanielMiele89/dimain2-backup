CREATE TABLE [Report].[V_0003_NewsletterVolumes] (
    [ID]                       INT         IDENTITY (1, 1) NOT NULL,
    [LionSendID]               INT         NULL,
    [EmailSendDate]            DATE        NULL,
    [ClubID]                   VARCHAR (7) NULL,
    [UsersSelectedForLionSend] INT         NULL,
    [UsersExportedFromActito]  INT         NULL,
    [UsersAfterValidation]     INT         NULL,
    [UsersEmailed]             INT         NULL
);

