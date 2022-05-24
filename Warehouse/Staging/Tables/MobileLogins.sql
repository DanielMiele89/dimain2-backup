CREATE TABLE [Staging].[MobileLogins] (
    [MobileLoginsID] BIGINT        IDENTITY (1, 1) NOT NULL,
    [RowNumber]      INT           NULL,
    [CustomerID]     VARCHAR (20)  NULL,
    [EventDateTime]  DATETIME      NULL,
    [EventTypeID]    TINYINT       NULL,
    [FileName]       VARCHAR (500) NULL,
    CONSTRAINT [PK_MobileLogins] PRIMARY KEY CLUSTERED ([MobileLoginsID] ASC) WITH (DATA_COMPRESSION = PAGE)
);

