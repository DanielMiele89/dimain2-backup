CREATE TABLE [Staging].[R_0183_LionSendVolumesCheck] (
    [ID]                       INT          IDENTITY (1, 1) NOT NULL,
    [LionSendID]               INT          NULL,
    [EmailSendDate]            DATE         NULL,
    [Brand]                    VARCHAR (7)  NULL,
    [Loyalty]                  VARCHAR (5)  NULL,
    [UsersSelectedForLionSend] VARCHAR (15) NULL,
    [UsersUploadedSFD]         INT          NULL,
    [UsersAfterSFDValidation]  INT          NULL,
    [UsersEmailed]             INT          NULL
);

