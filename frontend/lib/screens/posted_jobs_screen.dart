import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../utils/app_theme.dart';
import 'bids_screen.dart';

class PostedJobsScreen extends StatefulWidget {
  const PostedJobsScreen({super.key});

  @override
  State<PostedJobsScreen> createState() => _PostedJobsScreenState();
}

class _PostedJobsScreenState extends State<PostedJobsScreen> {
  final _api = ApiService();
  List<dynamic> _jobs = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadJobs();
  }

  Future<void> _loadJobs() async {
    try {
      setState(() => _loading = true);
      _jobs = await _api.getMyJobs();
    } catch (e) {
      if (mounted) showSnack(context, e.toString(), err: true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      appBar: AppBar(
        title: const Text('My Posted Jobs'),
        leading: const BackButton(color: kWhite),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: kWhite),
            onPressed: _loadJobs,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: kBlue))
          : _jobs.isEmpty
              ? _emptyState()
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _jobs.length,
                  itemBuilder: (ctx, i) => _jobCard(_jobs[i]),
                ),
    );
  }

  Widget _jobCard(Map<String, dynamic> job) {
    final status = job['status'] as String? ?? 'open';
    final isActive = status == 'active';
    final isOpen = status == 'open';
    final jobId = job['id'] as int?;
    
    return GestureDetector(
      onTap: () {
        if (isActive) {
          Navigator.pushNamed(context, '/active-job');
        } else if (isOpen && jobId != null) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => BidsScreen(jobId: jobId)),
          );
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: kWhite,
          borderRadius: BorderRadius.circular(18),
          boxShadow: kShadow,
          border: isActive ? Border.all(color: kGreen, width: 1.5) : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    job['title'] ?? 'Untitled',
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                      color: kBlack,
                    ),
                  ),
                ),
                buildTag(
                  status.toUpperCase(),
                  isActive ? kGreen : (isOpen ? kBlue : kGrey),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              job['description'] ?? '',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: kGrey, fontSize: 12),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.monetization_on_rounded, size: 16, color: kBlue),
                const SizedBox(width: 4),
                Text(
                  'Rs. ${(job['price'] as num?)?.toStringAsFixed(0) ?? '0'}',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(width: 16),
                const Icon(Icons.timer_outlined, size: 16, color: kPurple),
                const SizedBox(width: 4),
                Text(
                  job['urgency']?.toString().toUpperCase() ?? 'FLEXIBLE',
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            ),
            if (isOpen) ...[
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Icon(Icons.visibility_rounded, size: 14, color: kBlue),
                  const SizedBox(width: 4),
                  const Text(
                    'Tap to view bids',
                    style: TextStyle(fontSize: 11, color: kBlue),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _emptyState() => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.work_outline, size: 60, color: kGrey),
            const SizedBox(height: 16),
            const Text(
              'No jobs posted yet',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: kBlack),
            ),
            const SizedBox(height: 8),
            const Text('Tap + to post your first job', style: TextStyle(color: kGrey)),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => Navigator.pushNamed(context, '/post-job'),
              style: ElevatedButton.styleFrom(
                backgroundColor: kBlue,
                foregroundColor: kWhite,
              ),
              child: const Text('Post a Job'),
            ),
          ],
        ),
      );
}