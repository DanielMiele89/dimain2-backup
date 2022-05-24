CREATE TABLE [Email].[Newsletter_Volumes] (
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


GO
CREATE UNIQUE CLUSTERED INDEX [ucx_NV]
    ON [Email].[Newsletter_Volumes]([ID] ASC);

