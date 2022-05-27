CREATE TABLE [Staging].[CustomerEngagement_Customer_Segment] (
    [ID]                     INT          IDENTITY (1, 1) NOT NULL,
    [SegmentStartDate]       DATE         NULL,
    [SegmentEndDate]         DATE         NULL,
    [FanID]                  INT          NOT NULL,
    [Marketablebyemail]      INT          NULL,
    [Score]                  INT          NULL,
    [WLs_ForSegmentation]    INT          NULL,
    [EOs_ForSegmentation]    INT          NULL,
    [EngagementSegment]      VARCHAR (30) NULL,
    [DebitCard]              INT          NOT NULL,
    [CreditCard]             INT          NOT NULL,
    [BothDebitAndCreditCard] INT          NOT NULL,
    CONSTRAINT [PK_CustomerEngagement_Customer_Segment] PRIMARY KEY CLUSTERED ([ID] ASC)
);


GO
CREATE NONCLUSTERED INDEX [IX_CustomerEngagement_Customer_Segment]
    ON [Staging].[CustomerEngagement_Customer_Segment]([SegmentStartDate] ASC, [SegmentEndDate] ASC, [EngagementSegment] ASC)
    INCLUDE([FanID]);

