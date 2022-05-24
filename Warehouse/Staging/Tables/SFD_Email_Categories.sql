CREATE TABLE [Staging].[SFD_Email_Categories] (
    [ID]          INT          IDENTITY (1, 1) NOT NULL,
    [Category]    VARCHAR (35) NOT NULL,
    [ListName]    VARCHAR (20) NOT NULL,
    [QueryName]   VARCHAR (50) NOT NULL,
    [DisplayName] VARCHAR (30) NULL,
    PRIMARY KEY CLUSTERED ([ID] ASC)
);


GO
CREATE NONCLUSTERED INDEX [ix_SFD_Email_Categories_Category]
    ON [Staging].[SFD_Email_Categories]([Category] ASC);

