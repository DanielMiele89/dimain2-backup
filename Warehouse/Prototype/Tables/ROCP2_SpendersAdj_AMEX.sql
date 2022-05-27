CREATE TABLE [Prototype].[ROCP2_SpendersAdj_AMEX] (
    [BrandID]       SMALLINT     NULL,
    [Segment]       VARCHAR (50) NULL,
    [WeekLength]    SMALLINT     NULL,
    [Spenders]      INT          NULL,
    [Trans]         INT          NULL,
    [ATF]           REAL         NULL,
    [BASE_ATF]      REAL         NULL,
    [BASESpenders]  INT          NULL,
    [ATFRatio]      REAL         NULL,
    [SpendersRatio] REAL         NULL
);

