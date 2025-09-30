import 'package:flutter/material.dart';
import 'package:our_cabss/splash_screen/splash_screen.dart';

class PayFareAmountDilog extends StatefulWidget {
  double? fareAmount;
  PayFareAmountDilog({this.fareAmount});
  @override
  State<PayFareAmountDilog> createState() => _PayFareAmountDilogState();
}

class _PayFareAmountDilogState extends State<PayFareAmountDilog> {
  @override
  Widget build(BuildContext context) {
    bool darkTheme =
        MediaQuery.of(context).platformBrightness == Brightness.dark;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      backgroundColor: Colors.transparent,
      child: Container(
        margin: EdgeInsets.all(10),
        width: double.infinity,
        decoration: BoxDecoration(
          color: darkTheme ? Colors.black : Colors.blue,
        ),
        child: Column(
          children: [
            SizedBox(height: 20),

            Text(
              "Fare Amount".toUpperCase(),

              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: darkTheme ? Colors.amber.shade400 : Colors.white,
                fontSize: 16,
              ),
            ),

            SizedBox(height: 20),
            Divider(
              thickness: 2,
              color: darkTheme ? Colors.amber.shade400 : Colors.white,
            ),
                        SizedBox(height: 10),
             Text("₹"+widget.fareAmount.toString(),
             style: TextStyle(
              fontWeight: FontWeight.bold,
              color: darkTheme?Colors.amber.shade400:Colors.white,
              fontSize: 50,

             ),
             ),
                                     SizedBox(height: 10),
           Text("This is the total trip fare amount. please pay it to the driver",textAlign: TextAlign.center,style: TextStyle(
            color: darkTheme?Colors.amber.shade400:Colors.blue,
           ),),
           SizedBox(height: 10,),
           ElevatedButton(
            onPressed: (){
              Future.delayed(Duration(milliseconds: 10000),(){
            Navigator.pop(context,"Cash Paid");
            Navigator.push(context, MaterialPageRoute(builder: (c)=>SplashScreen()));

              });
              
            },
           style: ElevatedButton.styleFrom(
           backgroundColor: darkTheme?Colors.amber.shade400:Colors.white, ),

            child:Row(
              children: [
                Text("Pay Cash",style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: darkTheme?Colors.black:Colors.blue,
                ),),
                             Text("₹"+widget.fareAmount.toString(),
             style: TextStyle(
              fontWeight: FontWeight.bold,
              color: darkTheme?Colors.black:Colors.blue,
              fontSize: 50,

             ),
             ),
              ],
            ) )
          ],
        ),
      ),
    );
  }
}
