import '../../domain/entities/user.dart';
import '../../domain/entities/academy.dart';
import '../../domain/entities/branch.dart';
import '../../domain/entities/player.dart';
import '../../domain/entities/invitation.dart';
import '../../domain/entities/package_subscription.dart';
import '../../domain/entities/employee.dart';
import '../../domain/entities/attendance.dart';
import '../../domain/entities/salary.dart';
import '../../domain/entities/revenue.dart';
import '../../domain/entities/expense.dart';
import '../../domain/entities/activity_log.dart';

class MockDatabase {
  static final MockDatabase instance = MockDatabase._internal();
  MockDatabase._internal() {
    _initData();
  }

  late UserEntity currentUser;
  final List<UserEntity> users = [];
  final List<AcademyEntity> academies = [];
  final List<BranchEntity> branches = [];
  final List<PlayerEntity> players = [];
  final List<InvitationEntity> invitations = [];
  final List<PackageEntity> packages = [];
  final List<SubscriptionEntity> subscriptions = [];
  final List<EmployeeEntity> employees = [];
  final List<AttendanceEntity> attendanceRecords = [];
  final List<SalaryRecordEntity> salaryRecords = [];
  final List<RevenueEntity> revenues = [];
  final List<ExpenseEntity> expenses = [];
  final List<ActivityLogEntity> activityLogs = [];

  void _initData() {
    // Academies
    academies.addAll([
      AcademyEntity(
        id: 'academy-1',
        name: 'Stars Academy',
        sport: 'Football',
        logoUrl: 'https://images.unsplash.com/photo-1508098682722-e99c43a406b2?w=150',
        phone: '+1 (555) 019-2831',
        address: '100 Olympic Way, Sports City',
        createdAt: DateTime.now().subtract(const Duration(days: 365)),
        updatedAt: DateTime.now(),
      ),
      AcademyEntity(
        id: 'academy-2',
        name: 'Apex Athletics',
        sport: 'Basketball',
        logoUrl: 'https://images.unsplash.com/photo-1546519638-68e109498ffc?w=150',
        phone: '+1 (555) 048-9120',
        address: '450 Arena Boulevard, Eastside',
        createdAt: DateTime.now().subtract(const Duration(days: 180)),
        updatedAt: DateTime.now(),
      ),
    ]);

    // Users
    currentUser = UserEntity(
      id: 'user-1',
      name: 'Mahmoud Mohsin',
      email: 'mahmoud@starsacademy.com',
      phone: '+1 (555) 998-1122',
      avatarUrl: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=150',
      role: UserRole.admin,
      authorizedAcademyIds: ['academy-1', 'academy-2'],
      createdAt: DateTime.now().subtract(const Duration(days: 200)),
    );

    users.addAll([
      currentUser,
      UserEntity(
        id: 'user-2',
        name: 'Sarah Connor',
        email: 'sarah@starsacademy.com',
        phone: '+1 (555) 332-4455',
        avatarUrl: 'https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=150',
        role: UserRole.normalUser,
        authorizedAcademyIds: ['academy-1'],
        createdAt: DateTime.now().subtract(const Duration(days: 100)),
      ),
      UserEntity(
        id: 'user-3',
        name: 'Alex Rivera',
        email: 'alex@apexathletics.com',
        phone: '+1 (555) 778-9900',
        avatarUrl: 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=150',
        role: UserRole.admin,
        authorizedAcademyIds: ['academy-2'],
        createdAt: DateTime.now().subtract(const Duration(days: 150)),
      ),
    ]);

    // Branches
    branches.addAll([
      BranchEntity(
        id: 'branch-1',
        academyId: 'academy-1',
        name: 'Main Stadium Complex',
        address: '100 Olympic Way, Gate 4',
        phone: '+1 (555) 019-2831',
        imageUrl: 'https://images.unsplash.com/photo-1529900748604-07564a03e7a6?w=500',
        createdAt: DateTime.now().subtract(const Duration(days: 300)),
      ),
      BranchEntity(
        id: 'branch-2',
        academyId: 'academy-1',
        name: 'North Training Facility',
        address: '88 North Avenue, Sector 9',
        phone: '+1 (555) 019-8821',
        imageUrl: 'https://images.unsplash.com/photo-1577223625816-7546f13df25d?w=500',
        createdAt: DateTime.now().subtract(const Duration(days: 120)),
      ),
      BranchEntity(
        id: 'branch-3',
        academyId: 'academy-2',
        name: 'Apex Indoor Dome',
        address: '450 Arena Boulevard',
        phone: '+1 (555) 048-9120',
        imageUrl: 'https://images.unsplash.com/photo-1504450758481-7338eba7524a?w=500',
        createdAt: DateTime.now().subtract(const Duration(days: 150)),
      ),
    ]);

    // Players
    players.addAll([
      PlayerEntity(
        id: 'player-1',
        academyId: 'academy-1',
        branchId: 'branch-1',
        name: 'Omar Hassan',
        age: 14,
        phone: '+1 (555) 111-2233',
        sport: 'Football',
        status: 'Active',
        joinedDate: DateTime.now().subtract(const Duration(days: 90)),
        notes: 'Promising Striker',
      ),
      PlayerEntity(
        id: 'player-2',
        academyId: 'academy-1',
        branchId: 'branch-1',
        name: 'Lucas Silva',
        age: 16,
        phone: '+1 (555) 222-3344',
        sport: 'Football',
        status: 'Active',
        joinedDate: DateTime.now().subtract(const Duration(days: 60)),
        notes: 'Midfielder captain',
      ),
      PlayerEntity(
        id: 'player-3',
        academyId: 'academy-1',
        branchId: 'branch-2',
        name: 'Youssef Ali',
        age: 12,
        phone: '+1 (555) 333-4455',
        sport: 'Football',
        status: 'Active',
        joinedDate: DateTime.now().subtract(const Duration(days: 30)),
        notes: 'Junior goalkeeper',
      ),
      PlayerEntity(
        id: 'player-4',
        academyId: 'academy-2',
        branchId: 'branch-3',
        name: 'James Jordan',
        age: 17,
        phone: '+1 (555) 444-5566',
        sport: 'Basketball',
        status: 'Active',
        joinedDate: DateTime.now().subtract(const Duration(days: 45)),
        notes: 'Point Guard',
      ),
    ]);

    // Invitations
    invitations.addAll([
      InvitationEntity(
        id: 'inv-1',
        academyId: 'academy-1',
        email: 'coach.tariq@gmail.com',
        role: 'Assistant Coach',
        status: InvitationStatus.pending,
        sentAt: DateTime.now().subtract(const Duration(days: 2)),
        invitedBy: 'Mahmoud Mohsin',
      ),
      InvitationEntity(
        id: 'inv-2',
        academyId: 'academy-1',
        email: 'admin.linda@gmail.com',
        role: 'Administrator',
        status: InvitationStatus.pending,
        sentAt: DateTime.now().subtract(const Duration(days: 5)),
        invitedBy: 'Mahmoud Mohsin',
      ),
    ]);

    // Packages & Subscriptions
    packages.addAll([
      PackageEntity(
        id: 'pkg-free',
        title: 'Free Plan',
        price: 0.0,
        billingPeriod: 'Forever',
        features: ['Up to 1 Branch', 'Up to 25 Players', 'Basic Reports'],
        isFreeTier: true,
      ),
      PackageEntity(
        id: 'pkg-pro',
        title: 'Pro Academy',
        price: 99.0,
        billingPeriod: 'Monthly',
        features: ['Unlimited Branches', 'Up to 250 Players', 'Financial Analytics', 'Export Reports', 'Multi-user roles'],
      ),
      PackageEntity(
        id: 'pkg-enterprise',
        title: 'Enterprise Elite',
        price: 299.0,
        billingPeriod: 'Monthly',
        features: ['Unlimited Everything', 'Dedicated Account Manager', 'Custom Domain', '24/7 Priority Support'],
      ),
    ]);

    subscriptions.addAll([
      SubscriptionEntity(
        id: 'sub-1',
        academyId: 'academy-1',
        packageId: 'pkg-free',
        packageName: 'Free Plan',
        status: 'Active',
        startDate: DateTime.now().subtract(const Duration(days: 180)),
        endDate: DateTime.now().add(const Duration(days: 185)),
        pricePaid: 0.0,
      ),
      SubscriptionEntity(
        id: 'sub-2',
        academyId: 'academy-2',
        packageId: 'pkg-pro',
        packageName: 'Pro Academy',
        status: 'Active',
        startDate: DateTime.now().subtract(const Duration(days: 30)),
        endDate: DateTime.now().add(const Duration(days: 335)),
        pricePaid: 99.0,
      ),
    ]);

    // Employees
    employees.addAll([
      EmployeeEntity(
        id: 'emp-1',
        academyId: 'academy-1',
        name: 'Captain Zinedine',
        role: 'Head Coach',
        phone: '+1 (555) 777-1122',
        baseSalary: 3500.0,
        joinedDate: DateTime.now().subtract(const Duration(days: 200)),
      ),
      EmployeeEntity(
        id: 'emp-2',
        academyId: 'academy-1',
        name: 'Mona Khaled',
        role: 'Physical Trainer',
        phone: '+1 (555) 777-3344',
        baseSalary: 2200.0,
        joinedDate: DateTime.now().subtract(const Duration(days: 150)),
      ),
      EmployeeEntity(
        id: 'emp-3',
        academyId: 'academy-1',
        name: 'Hassan Mahmoud',
        role: 'Facility Supervisor',
        phone: '+1 (555) 777-5566',
        baseSalary: 1800.0,
        joinedDate: DateTime.now().subtract(const Duration(days: 100)),
      ),
    ]);

    // Attendance
    final today = DateTime.now();
    attendanceRecords.addAll([
      AttendanceEntity(
        id: 'att-1',
        academyId: 'academy-1',
        employeeId: 'emp-1',
        date: DateTime(today.year, today.month, today.day),
        status: AttendanceStatus.present,
        notes: 'On time for morning practice',
      ),
      AttendanceEntity(
        id: 'att-2',
        academyId: 'academy-1',
        employeeId: 'emp-2',
        date: DateTime(today.year, today.month, today.day),
        status: AttendanceStatus.present,
        notes: 'Conducted fitness session',
      ),
      AttendanceEntity(
        id: 'att-3',
        academyId: 'academy-1',
        employeeId: 'emp-3',
        date: DateTime(today.year, today.month, today.day),
        status: AttendanceStatus.late,
        notes: 'Arrived 15 mins late due to traffic',
      ),
    ]);

    // Salary Records
    salaryRecords.addAll([
      SalaryRecordEntity(
        id: 'sal-1',
        academyId: 'academy-1',
        employeeId: 'emp-1',
        employeeName: 'Captain Zinedine',
        amount: 3500.0,
        paymentDate: DateTime.now().subtract(const Duration(days: 10)),
        monthYear: 'July 2026',
        status: 'Paid',
        paymentMethod: 'Direct Deposit',
      ),
      SalaryRecordEntity(
        id: 'sal-2',
        academyId: 'academy-1',
        employeeId: 'emp-2',
        employeeName: 'Mona Khaled',
        amount: 2200.0,
        paymentDate: DateTime.now().subtract(const Duration(days: 10)),
        monthYear: 'July 2026',
        status: 'Paid',
        paymentMethod: 'Direct Deposit',
      ),
    ]);

    // Revenues
    revenues.addAll([
      RevenueEntity(
        id: 'rev-1',
        academyId: 'academy-1',
        title: 'Summer Tournament Sponsorship',
        collectedAmount: 5000.0,
        remainingAmount: 1500.0,
        category: 'Sponsor',
        date: DateTime.now().subtract(const Duration(days: 15)),
        description: 'First installment from Nike Sponsorship contract',
      ),
      RevenueEntity(
        id: 'rev-2',
        academyId: 'academy-1',
        title: 'Official Kits & Merchandise',
        collectedAmount: 2400.0,
        remainingAmount: 0.0,
        category: 'Merchandise',
        date: DateTime.now().subtract(const Duration(days: 8)),
        description: 'Sales of 60 official jersey sets',
      ),
    ]);

    // Expenses
    expenses.addAll([
      ExpenseEntity(
        id: 'exp-1',
        academyId: 'academy-1',
        name: 'Pitch Lighting & Maintenance',
        amount: 850.0,
        date: DateTime.now().subtract(const Duration(days: 12)),
        description: 'Replaced LED floodlight fixtures on Pitch A',
        category: 'Maintenance',
        notes: 'Paid to City Energy Tech',
      ),
      ExpenseEntity(
        id: 'exp-2',
        academyId: 'academy-1',
        name: 'New Training Balls & Cones',
        amount: 620.0,
        date: DateTime.now().subtract(const Duration(days: 20)),
        description: 'Purchased 30 FIFA approved training balls',
        category: 'Equipment',
        notes: 'Sports Supply Co invoice #9921',
      ),
    ]);

    // Activity Logs
    activityLogs.addAll([
      ActivityLogEntity(
        id: 'log-1',
        academyId: 'academy-1',
        userId: 'user-1',
        userName: 'Mahmoud Mohsin',
        action: 'Player Added',
        entityType: 'Player',
        details: 'Registered new player: Omar Hassan',
        timestamp: DateTime.now().subtract(const Duration(days: 90)),
      ),
      ActivityLogEntity(
        id: 'log-2',
        academyId: 'academy-1',
        userId: 'user-1',
        userName: 'Mahmoud Mohsin',
        action: 'Branch Added',
        entityType: 'Branch',
        details: 'Opened new branch: North Training Facility',
        timestamp: DateTime.now().subtract(const Duration(days: 120)),
      ),
      ActivityLogEntity(
        id: 'log-3',
        academyId: 'academy-1',
        userId: 'user-1',
        userName: 'Mahmoud Mohsin',
        action: 'Invitation Sent',
        entityType: 'Invitation',
        details: 'Invited coach.tariq@gmail.com as Assistant Coach',
        timestamp: DateTime.now().subtract(const Duration(days: 2)),
      ),
      ActivityLogEntity(
        id: 'log-4',
        academyId: 'academy-1',
        userId: 'user-1',
        userName: 'Mahmoud Mohsin',
        action: 'Expense Recorded',
        entityType: 'Expense',
        details: 'Recorded expense: Pitch Lighting (\$850.0)',
        timestamp: DateTime.now().subtract(const Duration(days: 12)),
      ),
    ]);
  }
}
