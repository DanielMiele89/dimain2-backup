CREATE TABLE [AWS].[FileUploadExceptions] (
    [ID]               INT            IDENTITY (1, 1) NOT NULL,
    [FileLogID]        INT            NOT NULL,
    [ExceptionDate]    DATETIME       CONSTRAINT [df_AWSFileExceptions_ExceptionDate] DEFAULT (getdate()) NOT NULL,
    [ErrorDescription] VARCHAR (1000) NULL,
    PRIMARY KEY CLUSTERED ([ID] ASC) WITH (FILLFACTOR = 95)
);

