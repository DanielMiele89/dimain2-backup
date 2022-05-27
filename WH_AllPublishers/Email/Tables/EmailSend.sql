CREATE TABLE [Email].[EmailSend] (
    [ID]            INT          IDENTITY (1, 1) NOT NULL,
    [Scheme]        VARCHAR (25) NOT NULL,
    [EmailType]     VARCHAR (25) NOT NULL,
    [EmailSendDate] DATE         NOT NULL,
    [CreatedDate]   DATETIME     NOT NULL,
    [CreatedBy]     VARCHAR (20) NULL,
    [TotalMembers]  INT          NULL
);

