import 'package:KlikGadget/screens/user/Navbar.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';

class Payment extends StatefulWidget {
  final String userId;
  final String address;
  final String paymentMethod;
  final String courier;
  final num totalAmount;
  final int totalQuantity;

  const Payment({
    super.key,
    required this.userId,
    required this.address,
    required this.paymentMethod,
    required this.courier,
    required this.totalAmount,
    required this.totalQuantity,
  });

  @override
  _PaymentState createState() => _PaymentState();
}

class _PaymentState extends State<Payment> {
  double _scale = 0.0;

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 80), () {
      setState(() {
        _scale = 1.0;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    // Screen width and height for responsive scaling
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Transaction Receipt',
          style: GoogleFonts.lato(),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(18.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: screenHeight * 0.0001), // Responsive spacing
            Center(
              child: Text(
                'Yeayy Your Payment Successfully',
                style: GoogleFonts.merriweather(
                  color: Colors.black,
                  fontSize: screenWidth * 0.03, // Responsive font size
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            SizedBox(height: screenHeight * 0.02), // Responsive spacing
            Center(
              child: AnimatedScale(
                scale: _scale,
                duration: const Duration(seconds: 1),
                child: Container(
                  width: screenWidth * 0.5, // Responsive image size
                  height: screenWidth * 0.5, // Make image square and responsive
                  decoration: const BoxDecoration(
                    image: DecorationImage(
                      image: AssetImage('assets/images/paket.png'),
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ),
            ),
            SizedBox(height: screenHeight * 0.03),
            Center(
              child: Text(
                "Your order has been confirmed and will be shipped shortly. Thank you for shopping with us!",
                textAlign: TextAlign.center,
                style: GoogleFonts.handlee(
                  color: const Color.fromARGB(255, 104, 104, 104),
                  fontSize: screenWidth * 0.03,
                  height: 1.2,
                ),
              ),
            ),

            SizedBox(height: screenHeight * 0.035),

            // Delivery details
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Delivery Details:',
                  style: GoogleFonts.lato(
                      fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const Divider(thickness: 2),
                SizedBox(height: screenHeight * 0.02),
                _buildDetailRow('User ID', widget.userId),
                _buildDetailRow('Address', widget.address),
                _buildDetailRow('Payment Method', widget.paymentMethod),
                _buildDetailRow('Courier', widget.courier),
                _buildDetailRow('Total Amount',
                    CurrencyFormat.convertToIdr(widget.totalAmount, 2)),
                _buildDetailRow(
                    'Total Quantity', '${widget.totalQuantity} items'),
              ],
            ),
            SizedBox(height: screenHeight * 0.05), // Responsive spacing
            Center(
              child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: BorderSide.strokeAlignCenter,
                      vertical: 15,
                    ),
                  ),
                  onPressed: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const HomePage(
                          userEmail: '',
                          username: '',
                        ),
                      ),
                    );
                  },
                  label: Text(
                    'BACK TO HOME',
                    style: GoogleFonts.lato(
                        color: const Color.fromARGB(255, 0, 0, 0)),
                  ),
                  icon: const Icon(Icons.house)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.lato(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: GoogleFonts.lato(color: Colors.black),
          ),
        ],
      ),
    );
  }
}

class CurrencyFormat {
  static String convertToIdr(num amount, int decimalDigit) {
    NumberFormat currencyFormatter = NumberFormat.currency(
      locale: 'id',
      symbol: 'Rp. ',
      decimalDigits: decimalDigit,
    );
    return currencyFormatter.format(amount);
  }
}
