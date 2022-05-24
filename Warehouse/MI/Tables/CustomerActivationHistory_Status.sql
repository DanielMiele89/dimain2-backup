CREATE TABLE [MI].[CustomerActivationHistory_Status] (
    [ID]         TINYINT      IDENTITY (1, 1) NOT NULL,
    [StatusDesc] VARCHAR (50) NULL,
    CONSTRAINT [PK_MI_CustomerActivationHistory_Status] PRIMARY KEY CLUSTERED ([ID] ASC)
);

