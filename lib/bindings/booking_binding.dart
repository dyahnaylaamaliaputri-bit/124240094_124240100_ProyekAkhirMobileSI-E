// lib/bindings/booking_binding.dart
// Binding untuk alur pemesanan tiket bioskop (PB-018, PB-019, PB-020, PB-021)

import 'package:get/get.dart';
import '../controllers/booking_cinema_controller.dart';
import '../controllers/booking_movie_controller.dart';
import '../controllers/booking_seat_controller.dart';
import '../controllers/order_summary_controller.dart';
import '../controllers/payment_controller.dart';
import '../controllers/ticket_detail_controller.dart';

import '../services/seat_service.dart';

class BookByCinemaBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<BookByCinemaController>(() => BookByCinemaController());
  }
}

class BookByMovieBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<BookByMovieController>(() => BookByMovieController());
  }
}

class BookingSeatBinding extends Bindings {
  @override
  void dependencies() {
    if (!Get.isRegistered<SeatService>()) {
      Get.lazyPut<SeatService>(() => SeatService.instance);
    }
    Get.lazyPut<BookingSeatController>(() => BookingSeatController());
  }
}

class OrderSummaryBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<OrderSummaryController>(() => OrderSummaryController());
  }
}

class PaymentBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<PaymentController>(() => PaymentController());
  }
}

class TicketDetailBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<TicketDetailController>(() => TicketDetailController());
  }
}
