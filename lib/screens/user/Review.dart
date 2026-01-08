// ignore_for_file: sort_child_properties_last

import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_fonts/google_fonts.dart';

class SubmitReviewPage extends StatefulWidget {
  final int productId;

  SubmitReviewPage({required this.productId});

  @override
  _SubmitReviewPageState createState() => _SubmitReviewPageState();
}

class _SubmitReviewPageState extends State<SubmitReviewPage> {
  num _rating = 0;
  final TextEditingController _commentController = TextEditingController();
  bool _isLoading = false;
  String _characterCount = "0/200"; // Track character count

  @override
  void initState() {
    super.initState();
    _commentController.addListener(_updateCharacterCount);
  }

  void _updateCharacterCount() {
    setState(() {
      _characterCount = "${_commentController.text.length}/200";
    });
  }

  @override
  Widget build(BuildContext context) {
    // Getting the screen width to make responsive adjustments
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      appBar: AppBar(
        title: Text("Submit Review"),
        elevation: 1,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Product Title
              Text(
                "Rate and Review",
              ),
              SizedBox(height: 20),

              // Rating Bar
              Center(
                child: RatingBar.builder(
                  initialRating: 0,
                  minRating: 1,
                  direction: Axis.horizontal,
                  allowHalfRating: true,
                  itemCount: 5,
                  itemPadding:
                      EdgeInsets.symmetric(horizontal: screenWidth * 0.02),
                  itemBuilder: (context, _) => Icon(
                    Icons.star,
                    color: Colors.amber,
                    size: screenWidth * 0.1, // Responsive icon size
                  ),
                  onRatingUpdate: (rating) {
                    setState(() {
                      _rating = rating;
                    });
                  },
                ),
              ),
              SizedBox(height: 20),

              // Comment Text Field
              TextField(
                controller: _commentController,
                maxLines: 4,
                maxLength: 200, // Limit to 200 characters
                decoration: InputDecoration(
                  hintText: "Write your review here...",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                        color: Colors.black), // Set border color to black
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                        color:
                            Colors.black), // Set enabled border color to black
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                        color:
                            Colors.black), // Set focused border color to black
                  ),
                  counterText: _characterCount, // Show character count
                ),
              ),

              SizedBox(height: 20),

              // Submit Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submitReview,
                  child: _isLoading
                      ? CircularProgressIndicator(color: Colors.white)
                      : Text(
                          "Submit Review",
                          style: GoogleFonts.lato(
                              color: Colors.white), // White text
                        ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black, // Black background
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Function to handle review submission
  void _submitReview() async {
    final String comment = _commentController.text;
    if (_rating == 0 || comment.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please provide a rating and comment')),
      );
      return;
    }

    setState(() {
      _isLoading = true; // Show loading state
    });

    final session = Supabase.instance.client.auth.currentSession;
    if (session != null) {
      final userid = session.user.id;
      // Create the review data
      final review = {
        'user_id': userid,
        'rating': _rating,
        'product_id': widget.productId,
        'comment': comment,
        'date': DateTime.now().toString(),
      };

      // Save the review to your database
      await Supabase.instance.client.from('reviews').insert(review);

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Review submitted successfully!')),
      );

      // Clear the form and pop the page
      _commentController.clear();
      setState(() {
        _rating = 0;
        _isLoading = false; // Reset loading state
      });
      Navigator.pop(context);
    } else {
      // Handle session error
      setState(() {
        _isLoading = false; // Reset loading state
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Session expired. Please log in again.')),
      );
    }
  }
}
