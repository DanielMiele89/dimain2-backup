CREATE TABLE [Prototype].[AMEX_SpenderAdj] (
    [BrandID]       SMALLINT     NULL,
    [Segment]       VARCHAR (50) NULL,
    [WeekLength]    SMALLINT     NULL,
    [Spenders]      INT          NULL,
    [Trans]         INT          NULL,
    [ATF]           REAL         NULL,
    [BASESpenders]  INT          NULL,
    [BASEATF]       REAL         NULL,
    [SpendersRatio] REAL         NULL,
    [ATFRatio]      REAL         NULL
);

