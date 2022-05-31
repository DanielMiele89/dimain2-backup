CREATE TABLE [Zoe].[Locations] (
    [ConsumerCombinationID] INT          NOT NULL,
    [LocationAddress]       VARCHAR (50) NOT NULL,
    [RowNum]                BIGINT       NULL
);


GO
CREATE UNIQUE CLUSTERED INDEX [ucx_Stuff]
    ON [Zoe].[Locations]([RowNum] ASC, [ConsumerCombinationID] ASC);

