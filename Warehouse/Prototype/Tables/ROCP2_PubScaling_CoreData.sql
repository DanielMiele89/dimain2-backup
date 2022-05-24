CREATE TABLE [Prototype].[ROCP2_PubScaling_CoreData] (
    [Clubname]        VARCHAR (50) NULL,
    [Partnerid]       INT          NULL,
    [PartnerName]     VARCHAR (50) NULL,
    [brandid]         INT          NULL,
    [AcquireL]        INT          NULL,
    [Cardholders]     INT          NULL,
    [Segment]         VARCHAR (25) NULL,
    [counts]          INT          NULL,
    [avgw_sales]      MONEY        NULL,
    [avgw_spder]      REAL         NULL,
    [RR]              REAL         NULL,
    [Segment_Percent] REAL         NULL,
    [Base_Cardholder] INT          NULL,
    [BASE_avgw_sales] MONEY        NULL,
    [BASE_avgw_spder] REAL         NULL,
    [BASE_Counts]     INT          NULL,
    [BASE_RR]         REAL         NULL,
    [BASE_Percent]    REAL         NULL,
    [LowFlag]         INT          NOT NULL
);

