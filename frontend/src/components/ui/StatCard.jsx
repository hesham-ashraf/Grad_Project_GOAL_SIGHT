import { IoArrowDownOutline, IoArrowUpOutline } from 'react-icons/io5'

const toneStyles = {
	primary: {
		iconBg: 'bg-primary-100 text-primary-600',
		badge: 'bg-primary-50 text-primary-600',
	},
	secondary: {
		iconBg: 'bg-secondary-100 text-secondary-600',
		badge: 'bg-secondary-50 text-secondary-600',
	},
	dark: {
		iconBg: 'bg-dark-200 text-dark-700',
		badge: 'bg-dark-100 text-dark-600',
	},
}

function StatCard({
	title,
	value,
	subtitle,
	trend,
	trendLabel,
	trendDirection = 'up',
	icon: Icon,
	tone = 'primary',
}) {
	const styles = toneStyles[tone] || toneStyles.primary
	const isUp = trendDirection === 'up'

	return (
		<article className="rounded-2xl border border-dark-200 bg-white p-5 shadow-sm transition-all hover:-translate-y-0.5 hover:shadow-md">
			<div className="flex items-start justify-between gap-3">
				<div>
					<p className="text-xs font-semibold uppercase tracking-wide text-dark-500">{title}</p>
					<p className="mt-2 text-2xl font-extrabold text-dark-900">{value}</p>
				</div>

				<span className={`inline-flex h-10 w-10 items-center justify-center rounded-xl ${styles.iconBg}`}>
					{Icon ? <Icon className="text-xl" /> : null}
				</span>
			</div>

			<p className="mt-3 text-sm text-dark-500">{subtitle}</p>

			<div className="mt-4 flex items-center gap-2 text-xs">
				<span
					className={`inline-flex items-center gap-1 rounded-full px-2 py-1 font-semibold ${
						isUp ? 'bg-green-100 text-green-700' : 'bg-red-100 text-red-700'
					}`}
				>
					{isUp ? <IoArrowUpOutline /> : <IoArrowDownOutline />}
					{trend}
				</span>
				<span className={`rounded-full px-2 py-1 font-medium ${styles.badge}`}>{trendLabel}</span>
			</div>
		</article>
	)
}

export default StatCard
