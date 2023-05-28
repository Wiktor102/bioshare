import "package:flutter/material.dart";

class ExpandableListView extends StatefulWidget {
  final Widget Function(BuildContext, int) itemBuilder;
  final Widget Function(BuildContext, int) separatorBuilder;
  final int visibleItemCount;
  final int itemCount;

  const ExpandableListView({
    required this.itemBuilder,
    required this.separatorBuilder,
    required this.visibleItemCount,
    required this.itemCount,
    super.key,
  });

  @override
  State<ExpandableListView> createState() => _ExpandableListViewState();
}

class _ExpandableListViewState extends State<ExpandableListView> with SingleTickerProviderStateMixin {
  final Duration animationDuration = const Duration(seconds: 1);
  bool isExpanded = false;

  void _toggleExpandedState() {
    setState(() {
      isExpanded = !isExpanded;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        AnimatedSize(
          duration: animationDuration,
          curve: Curves.easeInOut,
          child: SizedBox(
            height: isExpanded ? null : widget.visibleItemCount * 56.0,
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: isExpanded ? widget.itemCount : widget.visibleItemCount,
              itemBuilder: widget.itemBuilder,
              separatorBuilder: widget.separatorBuilder,
            ),
          ),
        ),
        ClipRRect(
          borderRadius: const BorderRadius.only(
            bottomLeft: Radius.circular(20),
            bottomRight: Radius.circular(20),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: _toggleExpandedState,
              child: Container(
                padding: const EdgeInsets.all(8.0),
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(
                      width: 1,
                      color: Theme.of(context).primaryColorLight,
                    ),
                  ),
                ),
                child: Icon(
                  isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                  color: Colors.black,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
