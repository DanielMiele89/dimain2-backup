CREATE TABLE [Email].[Newsletter_Customer] (
    [ID]           INT    IDENTITY (1, 1) NOT NULL,
    [FanID]        INT    NULL,
    [CompositeID]  BIGINT NULL,
    [RandomNumber] BIGINT NULL
);


GO
CREATE CLUSTERED INDEX [CIX_RandomComp]
    ON [Email].[Newsletter_Customer]([RandomNumber] ASC, [CompositeID] ASC) WITH (DATA_COMPRESSION = PAGE);

