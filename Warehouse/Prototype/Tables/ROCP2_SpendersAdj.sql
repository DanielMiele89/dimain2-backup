CREATE TABLE [Prototype].[ROCP2_SpendersAdj] (
    [BrandID]    SMALLINT     NULL,
    [Segment]    VARCHAR (50) NULL,
    [WeekLength] SMALLINT     NULL,
    [Spenders]   INT          NULL,
    [Trans]      INT          NULL,
    [ATF]        REAL         NULL,
    [BASE_ATF]   REAL         NULL,
    [ATFRatio]   REAL         NULL
);


GO
CREATE CLUSTERED INDEX [IDX_BID]
    ON [Prototype].[ROCP2_SpendersAdj]([BrandID] ASC);

