CREATE TABLE [Email].[EmailSend] (
    [ID]            INT          NOT NULL,
    [StatusID]      TINYINT      NOT NULL,
    [CreatedDate]   DATETIME     NOT NULL,
    [CreatedBy]     VARCHAR (20) NULL,
    [StartDateTime] DATETIME     NULL,
    [EndDateTime]   DATETIME     NULL,
    [TotalMembers]  INT          NULL,
    CONSTRAINT [PK_EmailSend] PRIMARY KEY CLUSTERED ([ID] ASC)
);

