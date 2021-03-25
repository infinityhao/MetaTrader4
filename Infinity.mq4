//+------------------------------------------------------------------+
//|                                                     Infinity.mq4 |
//+------------------------------------------------------------------+
#property copyright   "V"
#include <IncludeExample.mqh>

// External Variables
extern bool   DynamicLotSize = false;
extern double EquityPercent = 5;
extern double FixedLotSize = 1;

extern double StopLoss = 1000;
extern double TakeProfit = 1500;

extern int    TrailingStop = 250;
extern int    MinimumProfit = 1000;

extern int    Slippage = 50;
extern int    MagicNumber = 5649;

extern int    FastMAPeriod = 10;
extern int    SlowMAPeriod = 20;

extern bool   CheckOncePerBar = true;


// Global variables
int           BuyTicket;
int           SellTicket;

double        UsePoint;
int           UseSlippage;

datetime      CurrentTimeStamp;


// Init function
int init()
   {
      UsePoint = PipPoint(Symbol());
      UseSlippage = GetSlippage(Symbol(),Slippage);
   }
   
// Start Function
int start()
   {
   
      // Execute on bar open
      if(CheckOncePerBar == true)
         {
            int BarShift = 1;
            if(CurrentTimeStamp != Time[0])
               {
                  CurrentTimeStamp = Time[0];
                  bool NewBar = true;
               }
            else NewBar = false;
         }
      else
         {
            NewBar = true;
            BarShift = 0;
         }
         
      // Moving Average 
      double FastMA = iMA(NULL,1440,FastMAPeriod,0,3,0,BarShift);
      double SlowMA = iMA(NULL,1440,SlowMAPeriod,0,1,0,BarShift);      
      double LastFastMA = iMA(NULL,1440,FastMAPeriod,0,3,0,BarShift+1);
      double LastSlowMA = iMA(NULL,1440,SlowMAPeriod,0,1,0,BarShift+1);     
   
      // Stochastic
      //double KLine = iStochastic(NULL,1440,9,5,5,0,1,0,BarShift);
      //double DLine = iStochastic(NULL,1440,9,5,5,0,1,1,BarShift);
      //double LastKLine = iStochastic(NULL,1440,9,5,5,0,1,0,BarShift+1);
      //double LastDLine = iStochastic(NULL,1440,9,5,5,0,1,1,BarShift+1);
      
      // Calculate lot size
      double LotSize = CalcLotSize(DynamicLotSize,EquityPercent,StopLoss,FixedLotSize);
      LotSize = VerifyLotSize(LotSize);
      
      // Begin trade block
      if(NewBar == true)
         {
         
            // Buy order
            //if(KLine > DLine && LastKLine <= LastDLine && BuyMarketCount(Symbol(),MagicNumber) == 0)
            if(FastMA > SlowMA && LastFastMA <= LastSlowMA && BuyMarketCount(Symbol(),MagicNumber) == 0)
               {
                  // Close sell orders
                  if(SellMarketCount(Symbol(),MagicNumber) > 0)
                     {
                        CloseAllSellOrders(Symbol(),MagicNumber,Slippage);
                     }
                  
                  // Open buy order
                  BuyTicket = OpenBuyOrder(Symbol(),LotSize,UseSlippage,MagicNumber);
                  
                  // Order modification
                  if(BuyTicket > 0 && (StopLoss > 0 || TakeProfit > 0))
                     {
                        OrderSelect(BuyTicket,SELECT_BY_TICKET);
                        double OpenPrice = OrderOpenPrice();
                        
                        // Calculate and verify stop loss and take profit
                        double BuyStopLoss = CalcBuyStopLoss(Symbol(),StopLoss,OpenPrice);
                        if(BuyStopLoss > 0) BuyStopLoss = AdjustBelowStopLevel(Symbol(),BuyStopLoss,5);
                        
                        double BuyTakeProfit = CalcBuyTakeProfit(Symbol(),TakeProfit,OpenPrice);
                        if(BuyTakeProfit > 0) BuyTakeProfit = AdjustAboveStopLevel(Symbol(),BuyTakeProfit,5);
                        
                        // Add stop loss and take profit
                        AddStopProfit(BuyTicket,BuyStopLoss,BuyTakeProfit);
                     }
               }
                        

            // Sell order
            //if(KLine < DLine && LastKLine >= LastDLine && SellMarketCount(Symbol(),MagicNumber) == 0)
            if(FastMA < SlowMA && LastFastMA >= LastSlowMA && SellMarketCount(Symbol(),MagicNumber) == 0)            
               {
                  // Close buy orders
                  if(BuyMarketCount(Symbol(),MagicNumber) > 0)
                     {
                        CloseAllBuyOrders(Symbol(),MagicNumber,Slippage);
                     }
                  
                  // Open sell order
                  SellTicket = OpenSellOrder(Symbol(),LotSize,UseSlippage,MagicNumber);
                  
                  // Order modification
                  if(SellTicket > 0 && (StopLoss > 0 || TakeProfit > 0))
                     {
                        OrderSelect(SellTicket,SELECT_BY_TICKET);
                        OpenPrice = OrderOpenPrice();
                        
                        // Calculate and verify stop loss and take profit
                        double SellStopLoss = CalcSellStopLoss(Symbol(),StopLoss,OpenPrice);
                        if(SellStopLoss > 0) SellStopLoss = AdjustAboveStopLevel(Symbol(),SellStopLoss,5);
                        
                        double SellTakeProfit = CalcSellTakeProfit(Symbol(),TakeProfit,OpenPrice);
                        if(SellTakeProfit > 0) SellTakeProfit = AdjustBelowStopLevel(Symbol(),SellTakeProfit,5);
                        
                        // Add stop loss and take profit
                        AddStopProfit(SellTicket,SellStopLoss,SellTakeProfit);
                     }
               }   
            
                                               
            // Close Buy Order Only
            //if(CloseOrder == true && BuyMarketCount(Symbol(),MagicNumber) > 0)
            //   {
            //      CloseAllBuyOrders(Symbol(),MagicNumber,Slippage);
            //      CloseOrder = false;
            //   }
               
            // Close Sell Order Only
            //if(CloseOrder == true && SellMarketCount(Symbol(),MagicNumber) > 0)
            //   {
            //      CloseAllSellOrders(Symbol(),MagicNumber,Slippage);
            //      CloseOrder = false;
            //   }
               
         }  // End trade block
         
         
         // Adjust trailing stops
         if(BuyMarketCount(Symbol(),MagicNumber) > 0 && TrailingStop > 0)
            {
               BuyTrailingStop(Symbol(),TrailingStop,MinimumProfit,MagicNumber);
            }
            
         if(SellMarketCount(Symbol(),MagicNumber) > 0 && TrailingStop > 0)
            {
               SellTrailingStop(Symbol(),TrailingStop,MinimumProfit,MagicNumber);
            }   
            
         return(0);
   } 
                        