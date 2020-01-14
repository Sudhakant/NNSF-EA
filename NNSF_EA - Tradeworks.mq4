//+------------------------------------------------------------------+
//| A No Non-Sense Forex Trading Strategy - adopted from VP of Nononsenseforex.com |
//| Copyright 2019, PilTrader. |
//| http://pinoyFxTrader.blogspot.com |
//+------------------------------------------------------------------+
#property copyright   "2019, PilTrader."
#property link        "http://pinoyFxTrader.blogspot.com"
#property description " No-NON-Sense Forex Strategy - adopted from VP's strategy of Nononsenseforex.com " 
/*          FOR TRADEWORKS
                    INDICATORS
                        > SMA 20 at any  timeframe"  
                        > Ichimoku - The Tenkan-sen & Kijun-sen only (1st conf indicator)
                        > RVI - (2nd conf indicator)
                        > ATR - for Money management concerns
                    LOGIC
                        ** If no Existing Trade for the current instrument
                        >> if Price crosses 20SMA to the upside and if candle's close  is above 20SMA - Buy ENtry
                        >> The entry shal be confirmed by either of the Two(2) confirmation indicators
                           Depending on the choice of the user at EA Settings
                        >> If confirmed, EA shall take a look at the volume if there is sufficient volume
                        >> If volume is sufficient, the EA will calculate the TP and SL level based on ATR
                        >> If (Close - 20SMA) > 1.24*(ATR) , never trade
                        >> EA will execute the BUY order right upon Open of the candle.
                       
                      // "              3.  Manage Trade " 

    ==============================================================================================================
    LOGS 
    ==============================================================================================================
    fOR tRADeWorks - SImplified
 */
#define MAGICNUM  20131111

// Define our Parameters
input double Lots          = 0.01;
// input bool UseMM = true;
input int PercentRisk = 1;
// input int TakeProfit       = 3500; // No take Profit because this is a trend following
input int StopLoss         = 0; // The default stop loss (0 disable)
input int TakeProfit = 0; // Take profit will be dynamically computed based on ATR
input int TrailingStop = 0; // Trail after 1000 points distance (0 disable)
input ENUM_MA_METHOD SMA_method = 1;   // Averaging method: 0 - SMA, 1 - EMA, 2 - SMMA, 3 - LWMA  
input int BaseLinePeriod  = 20;  //  EMA Trend Period at D1 Chart
input int ConfIndi = 2;  // 1 - RVI, 2 - Ichimoku   
// input int ATR_Period = 14; // ATR default period
input int RVI_period = 14;  // RVI period
// input int TimeFrame = 5; // to be feed in ChartTimeFrame() 1=1, 2=5m 3=15, 4 = 30, 5=H1, ...
// int Sell_counter = 0;
// int Buy_counter = 0;
//+------------------------------------------------------------------+
//| expert initialization functions                                  |
//+------------------------------------------------------------------+
int init()
    {
    // ===============================================
    Print("MODE_LOTSIZE =" , MarketInfo(Symbol(),MODE_LOTSIZE), ", Symbol = ", Symbol());
    Print("MODE_MINLOT = ", MarketInfo(Symbol(),MODE_MINLOT), ", Symbol = ", Symbol());
    Print("MODE_LOTSTEP = ", MarketInfo(Symbol(),MODE_LOTSTEP), ", Symbol = ", Symbol());
    Print("MODE_MAXLOT = ", MarketInfo(Symbol(),MODE_MAXLOT), ", Symbol = ", Symbol());
    Print("AccountStopoutLevel() = ", AccountStopoutLevel());
    Print("AccountFreeMarginCheck = ", AccountFreeMarginCheck(Symbol(), OP_SELL, 0.01));
  
    // ===============================================

  return(0);
}
int deinit()
{
  return(0);
}

//+------------------------------------------------------------------+
//    TimeFrame Feeder Function
//     if (chartTimeFrame == 1)  //1 minute      
//     if (chartTimeFrame == 2)  //5 minute
//     if (chartTimeFrame == 3)  //15 minute
//     if (chartTimeFrame == 4)  //30 minute
//     if (chartTimeFrame == 5)  // 1 hour
//     if (chartTimeFrame == 6)  // 4 hour
//     if (chartTimeFrame == 7)  // Daily
//     if (chartTimeFrame == 8)  // Weekly
//     if (chartTimeFrame == 9)  // Monthly
ENUM_TIMEFRAMES ChartTimeFrame(int chartTimeFrame){
    if (chartTimeFrame == 1)
      return PERIOD_M1;                     //1 minute
    if (chartTimeFrame == 2)
      return PERIOD_M5;                     //5 minute
    if (chartTimeFrame == 3)
      return PERIOD_M15;                     //15 minute
    if (chartTimeFrame == 4)
      return PERIOD_M30;                     //30 minute
    if (chartTimeFrame == 5)
      return PERIOD_H1;                     // 1 hour
    if (chartTimeFrame == 6)
      return PERIOD_H4;                     // 4 hour
    if (chartTimeFrame == 7)
      return PERIOD_D1;                     // Daily
    if (chartTimeFrame == 8)
      return PERIOD_W1;                     // Weekly
    if (chartTimeFrame == 9)
      return PERIOD_MN1;                    // Monthly
    return PERIOD_CURRENT;
}
//====================================================================================
// INDICATORS
//====================================================================================
// Time Frame must be of type PERIOD
//  _mode is MODE_SMA, MODE_EMA 
double BaseLine(int _shiftPeriod){
  return  iMA(NULL, ChartTimeFrame(0), BaseLinePeriod, 0, SMA_method, PRICE_CLOSE, _shiftPeriod);
  } //

// =====================================================================================
double Previous_High(int _timeFrame, int _shfitPeriod){
   return iHigh(NULL, _timeFrame, _shfitPeriod);
}

double Previous_Low(int _timeFrame, int _shfitPeriod) {
    return iLow(NULL, _timeFrame, _shfitPeriod);
}

double Previous_Close(int _timeFrame, int _shfitPeriod) {
      return iClose(NULL, _timeFrame, _shfitPeriod);                 
} 

double Previous_Open (int _timeFrame, int _shfitPeriod) {
 return iOpen( NULL, _timeFrame, _shfitPeriod);              
}

double Current_Low(int _timeFrame){
  return iLow(NULL, _timeFrame, 0);
}

double Current_High(int _timeFrame){
  return iHigh(NULL, _timeFrame, 0);
}

double Current_Close (int _timeFrame) {
  return iClose( NULL, _timeFrame,  0);   
}

double Current_Open (int _timeFrame){
  return iOpen( NULL, _timeFrame, 0);           
}

//  Using the information of the 20 EMA
//  Returns :
//          1 : Only Buy and candles are forming above the Baseline
//          2 : ONly Sell and candles are forming below the Baseline
// -------------------------------------------------------
int CurrentDirection(ENUM_TIMEFRAMES _timeFrame){
   // Long  - 1
   if (Previous_Close(_timeFrame, 1) > BaseLine(0))
      return 1;
   // Short - 2  
   if (Previous_Close(_timeFrame, 1)< BaseLine(0)) 
      return 2; //"Candles are formed above 200 EMA") 
  return 0;
} // End CurrentDirection() Function

// An instance where We look for confirmation to BUY or To Sell
// Take the Trade if the confirmation indicator says okay to trade
//  Two Functions 
//      1. OkToBuy(_confIndi) , _confIndi is either 1 or 2
//      2. OkToSell(_confIndi)
//          ConfIndi  1: for RVI as the confirmation Indicator
//                    2: for ICHIMOKU as the confirmation Indicator
// ----------------------------------------------------
bool OkToBuy(int _confIndi){
    double _main, _signal, _conf2_main, _conf2_signal;
    if (!(CurrentDirection(ChartTimeFrame(0))==1)) 
        return false;
    if  (_confIndi == 1) {
        // _confIndi is RVI(period)
        // Check for confirmation using RVI
        _signal = iRVI(NULL, 0, RVI_period, MODE_SIGNAL, 0);
        _main = iRVI(NULL,0,RVI_period, MODE_MAIN,0);
        _conf2_signal =iIchimoku(NULL,0,9,26,52,MODE_TENKANSEN,0); // Tenkan Sen
        _conf2_main =iIchimoku(NULL,0,9,26,52,MODE_KIJUNSEN,0); // Kijun Sen
        if ((_signal < _main) && (_conf2_signal > _conf2_main))
          return true;
        } 
    if (_confIndi == 2){
          // _confIndi is Ichimoku
          //  Check for confirmation using ICHIMOKU
          _signal =iIchimoku(NULL,0,9,26,52,MODE_TENKANSEN,0); // Tenkan Sen
          _main =iIchimoku(NULL,0,9,26,52,MODE_KIJUNSEN,0); // Kijun Sen
          _conf2_signal = iRVI(NULL, 0, RVI_period, MODE_SIGNAL, 0);
          _conf2_main = iRVI(NULL,0,RVI_period, MODE_MAIN,0);
        if ((_signal > _main) && (_conf2_signal < _conf2_main))
          return true;
        }
    return false;

  }


bool OkToSell(int _confIndi){
    double _main, _signal, _conf2_main, _conf2_signal;
    if (!(CurrentDirection(ChartTimeFrame(0))==2)) 
    if  (_confIndi == 1) 
        {
        // _confIndi is RVI(period)
        _signal = iRVI(NULL, 0, RVI_period, MODE_SIGNAL, 0);
        _main = iRVI(NULL,0,RVI_period, MODE_MAIN,0);
        _conf2_signal =iIchimoku(NULL,0,9,26,52,MODE_TENKANSEN,0); // Tenkan Sen
        _conf2_main =iIchimoku(NULL,0,9,26,52,MODE_KIJUNSEN,0); // Kijun Sen
         if ((_signal > _main ) && (_conf2_signal < _conf2_main))
           return true;
        } 
        else
          return false;
    if  (_confIndi == 1) {
          // _confIndi is Ichimoku
           _signal =iIchimoku(NULL,0,9,26,52,MODE_TENKANSEN,0); // Tenkan Sen
          _main =iIchimoku(NULL,0,9,26,52,MODE_KIJUNSEN,0); // Kijun Sen
          _conf2_signal = iRVI(NULL, 0, RVI_period, MODE_SIGNAL, 0);
          _conf2_main = iRVI(NULL,0,RVI_period, MODE_MAIN,0);
          if ((_signal < _main ) && (_conf2_signal > _conf2_main))
           return true;
        }
        else
          return false;
        
     return false;
    
} // End of OkToSell - this is one of the two(2) functions that validates/confirm the signal


// ----------------------------------------------------------------------------------
// This is to check for a sell signal - 
// Concept: While price are at above the baseling, the EA shall look for a Sell Signal
//          It is a SELL signal if the previous bar Open was Above the baseline and the 
//          Current Open is now BELOW the Baseline
// The Confirmation Indicator shall validate if Okay to sell
bool SellSignal(){
 if ((Previous_Open(ChartTimeFrame(0), 1) > BaseLine(0)) &&
      (Current_Open(ChartTimeFrame(0)) < BaseLine(0))) {
      // Print ("SELL Signal Spotted: Price crosses the baseline and open Below of the  Baseline. ");
      return true; // Sell Signal Spotted!!!
    }

  // //  Price Pulbacks / Retraces from the Baseline
  //  if ((Previous_High(ChartTimeFrame(TimeFrame), 1) < BaseLine(0)) &&
  //     (Current_High(ChartTimeFrame(TimeFrame)) > BaseLine(0) && Current_Close(ChartTimeFrame(TimeFrame)) < BaseLine(0) )) {
  //     Print("SELL Signal Spotted: Price retraces in the  Baseline Resistance. ");
  //     return true; // Sell Signal Spotted!!!
  //   }     

  // // Price Gaps crossing over the baseline
  //   if ((Previous_Low(ChartTimeFrame(TimeFrame), 1) > BaseLine(0)) &&
  //       (Current_Open(ChartTimeFrame(TimeFrame)) < BaseLine(0))){
  //     Print("SELL Signal Spotted: Price GAPS from above Baseline to below Baseline. ");
  //     return true;
  //   }
  return false;

} // End SellSignal() Function


// -----------------------------------------------------------
// This is to check for a BUY signal - 
// Concept: While price are at Below the baseling, the EA shall look for a BUY Signal
//          It is a BUY signal if the previous bar Open was Below the baseline and the 
//          Current Open is now BELOW the Baseline
// The Confirmation Indicator shall validate if Okay to BUY
bool BuySignal(){
  // Price Cross over
  if ((Previous_Open(ChartTimeFrame(0), 1) < BaseLine(0)) &&
      (Current_Open(ChartTimeFrame(0)) > BaseLine(0))) {
      // Print("Buy Signal Spotted: Price crosses the baseline and open above the  Baseline. ");
      return true; // Buy Signal Spotted!!!
    }
  //  Price Pulbacks / Retraces from the Baseline
  // if ((Previous_Low(ChartTimeFrame(TimeFrame)) > BaseLine()) &&
  //     (Current_Low(ChartTimeFrame(TimeFrame)) < BaseLine() && Current_Close(ChartTimeFrame(TimeFrame)) > BaseLine() )) {
  //     Print("Buy Signal Spotted: Price retraces in the  Baseline Support. ");
  //     return true; // Buy Signal Spotted!!!
  //   }     
  //    // Price Gaps crossing over the baseline
  // if ((Previous_High(ChartTimeFrame(TimeFrame)) < BaseLine()) &&
  //       (Current_Open(ChartTimeFrame(TimeFrame)) > BaseLine())){
  //     Print("SELL Signal Spotted: Price GAPS from below the  Baseline to the above of the Baseline. ");
  //     return true;
  //   }
  return false;
} //End of BuySignal() Function

// Manage existing Open Trades
// Parameters - _total => Number of trades
void ManageTrade(int _total ){
  int _cnt;
  for (_cnt = 0; _cnt < _total; _cnt++)
  {
    if (!OrderSelect(_cnt, SELECT_BY_POS, MODE_TRADES))
      continue;

    if (OrderType() <= OP_SELL &&  // check for opened position
        OrderSymbol() == Symbol()) // check for symbol
    {
      //--- long position is opened
      if (OrderType() == OP_BUY){
        //--- check for trailing stop
        if (TrailingStop > 0) TrailStopBuy(TrailingStop);
        // -- Check for  SelSignal is detected, then Close Buy if spotted.
        //  Call a function that closes the specific order.
        // 
        //      CODE RESIDES HERE
        // 
      }
    else // go to short position
    {
      //--- check for trailing stop
      // Print("OrderType()==OP_SELL is ", (OrderType()==OP_SELL));
      // Print("OrderType()==OP_BUYL is ", (OrderType()==OP_BUY));
      // Print("There is an order to modify (Type):",OrderType(), " and Trailing Stop = ", TrailingStop);
      if (TrailingStop > 0) TrailStopSell(TrailingStop);
   
    } //End Else condition for Going Shorts 
   } // End OrderType() <= OP_SELL
  } //End of For Loop
} //End of ManageTrade() Function

//-----------------------------------------------------------------
//  TrailStopBuy() function
//  Receives parameter : TrailingStop
void TrailStopBuy(int _trailingStop){
   if (Bid - OrderOpenPrice() > Point * _trailingStop)
          {
            if (OrderStopLoss() < Bid - Point * _trailingStop)
            {
              //--- modify order and exit
              if (!OrderModify(OrderTicket(), OrderOpenPrice(), Bid - Point * _trailingStop, OrderTakeProfit(), 0, Green))
                Print("OrderModify error ", GetLastError());
              return;
            }
          }
} // End of TrailStop() Function

//-----------------------------------------------------------------
//  TrailStopSell() function
//  Receives parameter : TrailingStop
void TrailStopSell(int _trailingStop){
    if ((OrderOpenPrice() - Ask) > (Point * _trailingStop))
    {
      if ((OrderStopLoss() > (Ask + Point * _trailingStop)) || (OrderStopLoss() == 0))
      {
        //--- modify order and exit
        if (!OrderModify(OrderTicket(), OrderOpenPrice(), Ask + Point * _trailingStop, OrderTakeProfit(), 0, Red))
          Print("OrderModify error ", GetLastError());
        return;
      }
    }
} // End of TrailStopSell() Function

//+------------------------------------------------------------------+
//+ Run the algorithm                                               |
//+------------------------------------------------------------------+
int start(){ 
  int ticket, total;
  double ShortSL, ShortTP, LongSL, LongTP;
  
  // Get the current total orders
  total = OrdersTotal();
  if (total > 0){
    // Manage existing Trades
    // Print("Should Manage Trades here....");
    ManageTrade(total);
  }
  
  // Only open one trade at a time..
  if(total < 1){
     // Calculate Stop Loss  and Take profit levels based on Pre Defined SL & TP Levels
    if(StopLoss > 0){
      LongSL =  Ask-(StopLoss*Point);
      ShortSL = Bid+(StopLoss*Point);
        }
    if(TakeProfit > 0){
      LongTP = Ask+(TakeProfit*Point);
      ShortTP = Bid-(TakeProfit*Point);
        }
    
    Comment("Current SPREAD in points : " + MarketInfo(NULL, MODE_SPREAD) + "\n"+
              "Spread in Pips: " + (MarketInfo(NULL, MODE_SPREAD) * Point) +  "POINT : " + Point + "  DIGITS: " + Digits() + "\n" +
              "Tick Value: " + MarketInfo(Symbol(),MODE_TICKVALUE) +"\n"+"\n"+
              "Trade Direction (1) UP (2) DOWN : " + CurrentDirection(ChartTimeFrame(0)) + "\n" +
              " PercentRisk:", PercentRisk, "  LongStopLoss: ", LongSL, "  ShortStopLoss: ", ShortSL + "\n"+
              "MA 20 Value (current/ [5 periods ago]): " + BaseLine(0) +  "/" + BaseLine(5) +"\n" +
              "Checking for SELL Entry: " + SellSignal() +  "\n"+
              "Checking for BUY Entry: " + BuySignal() +   "\n" +
              "Using Ichimoku - Okay to Buy Now? : " + OkToBuy(2) + "\n" +
              "Using RVI - Okay to Buy Now? : " + OkToBuy(1) + "\n" +
              "Using Ichimoku - Okay to Sell Now? : " + OkToSell(2) + "\n" +
              "Using RVI - Okay to Sell Now? : " + OkToSell(1)+ "\n" +
              "Sell ENtry:" + SellSignal() +"   Buy Entry: " + BuySignal());

    if (BuySignal()== true){
        // Buy Signal Spotted
        //-----------------------------------------------------
        if  (OkToBuy(ConfIndi)){ 
           
           ticket =  OrderSend(Symbol(),
                      OP_BUY, 
                      Lots, Ask,5, LongSL, LongTP, 
                      "NNSF - BUY",MAGICNUM,0,Blue);
            if(ticket > 0){
              if(OrderSelect(ticket, SELECT_BY_TICKET, MODE_TRADES))
                Print("BUY Order Opened: ", OrderOpenPrice(), " SL:", LongSL, " TP: ", LongTP);
              }
              else
                Print("Error Opening BUY  Order: ", GetLastError());
                return(0);
            } //End If OkToBuy() Function Call
    } // End If BuySignal() Function Call
 
    // SHORT ONLY MODE
    // ---------------------------------------
    // Check for Sell Signal
    // Sell - Short position only
    if (SellSignal() == true){
      if (OkToSell(ConfIndi)){  
          ticket =  OrderSend(Symbol(), 
                  OP_SELL, 
                  Lots, Bid,5, ShortSL, ShortTP, 
                  "NNSF - SELL",MAGICNUM,0,Red);
            if(ticket > 0){
              if(OrderSelect(ticket, SELECT_BY_TICKET, MODE_TRADES))
                Print("SELL Order Opened: ", OrderOpenPrice(), " SL:", ShortSL, " TP: ", ShortTP);
              }
              else
                Print("Error Opening SELL Order: ", GetLastError());
                return(0);
            } //End If SellSignal() Function Call
       } // End If OkToSell() Function Call
   } //End If (Total < 1) Condition
return 0;
} //End Start() Function