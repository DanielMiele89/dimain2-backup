CREATE TABLE [dbo].[AdSpace] (
    [ID]        INT           IDENTITY (1, 1) NOT NULL,
    [Name]      NVARCHAR (45) NULL,
    [Mandatory] BIT           NULL,
    CONSTRAINT [PK_AdSpace] PRIMARY KEY CLUSTERED ([ID] ASC)
);

